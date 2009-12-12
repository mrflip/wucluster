#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'wukong/extensions'

HADOOP_EC2_DIR = File.expand_path(File.dirname(__FILE__))

#
# Cluster holds our idea of a hadoop cluster,
# as embodied in the hadoop-ec2 config files
#
Cluster = Struct.new(:name)
Cluster.class_eval do
  # The raw cluster_role_node_volume_tree from the cloudera EC2 cluster
  # description file
  def cluster_role_node_volume_tree
    @cluster_role_node_volumes ||= JSON.load(File.open(HADOOP_EC2_DIR+"/ec2-storage-#{name}.json"))
  end

  # Turn the cluster_role_node_volume_tree into a flat list of volumes,
  # an hash indexed by [role,node_idx,node_vol_idx]
  def load_volumes!
    @volumes = {}
    cluster_role_node_volume_tree.each do |role, cluster_node_volumes|
      cluster_node_volumes.each_with_index do |volumes, node_idx|
        volumes.each_with_index do |volume, node_vol_idx|
          @volumes[[role, node_idx, node_vol_idx]] = Ec2Volume.new(name, role, node_idx, node_vol_idx, volume['device'], volume['mount_point'], volume['volume_id'])
        end
      end
    end
    @volumes
  end

  # Hash of volumes, indexed by [role, node_idx, node_vol_idx]
  # Ex:
  #    p cluster.volumes[['master', 0, 0]]
  #    => #<struct Ec2Volume cluster="gibbon", role="master", node_idx=0, volume_idx=0, device="/dev/sdh", mount_point="/mnt/home", volume_id="vol-1cfa0475">
  def volumes
    @volumes ||= load_volumes!
  end

  # Put away this cluster:
  # * ensure all volumes are detached
  # * snapshot all volumes
  # * ... wait a bit ...
  # * for every snapshot on this cluster that was completed in the last hour,
  #   - delete its corresponding volume
  #   - delete all snapshots older than it
  def put_away_volumes
    volumes.each do |rnv_id, vol|
      puts "Putting away\t#{vol.description}"
      # puts `echo ec2-create-snapshot -d '#{vol.handle}' #{vol.volume_id}`
      p Ec2Volume.from_handle(vol.handle)
    end
  end
end

ClusterMount = Struct.new(
  :cluster,
  :role,
  :node_idx,
  :node_vol_idx,
  :device,
  :mount_point,
  :volume_id
  )
ClusterMount.class_eval do
  def initialize *args
    super *args
    self.coerce_to_int!(:node_idx,   true)
    self.coerce_to_int!(:node_vol_idx, true)
  end

  # Summary name for this volume
  # Ex:  gibbon+master+01+00+/dev/sdh+/mnt/home+vol-1cfa0475
  def handle
    [cluster, role, "%02d"%node_idx, "%02d"%node_vol_idx, device, mount_point, volume_id].join("+")
  end
  # readable-ish description
  def description
    # "%-15s\tvolume for\t%15s\t%-7s\tnode #\t%7d\t%7d" % [mount_point, cluster, role, node_idx, node_vol_idx]
    handle.gsub(/\+/,"\t")
  end
  # recreate volume from handle
  def self.from_handle handle
    self.new *handle.split("+", self.keys.length)
  end

  def size()          ec2_volume[:size] end
  def from_snapshot() ec2_volume[:from_snapshot] end
  def region()        ec2_volume[:region] end
  def state()         ec2_volume[:state]  end
  def created_at()    ec2_volume[:created_at]  end
  def ec2_volume
    Ec2Volumes.find(volume_id)
  end
end


# Cluster.new(:gibbon).put_away_volumes
# Ec2Snapshot.list_all

Ec2Volumes.list_all

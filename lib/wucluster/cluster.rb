module Wucluster
  #
  # Cluster holds our idea of a hadoop cluster,
  # as embodied in the hadoop-ec2 config files
  #
  Cluster = Struct.new(:name)
  Cluster.class_eval do
    cattr_accessor :all
    self.all = {}
    def initialize *args
      super *args
      raise "duplicate cluster #{name}" if self.class.all[name]
      self.class.all[name] = self
    end

    # Put away this cluster:
    # * ensure all volumes are detached
    # * snapshot all volumes
    # * ... wait a bit ...
    # * for every snapshot on this cluster that was completed in the last hour,
    #   - delete its corresponding volume
    #   - delete all snapshots older than it
    def put_away_volumes
      volumes.sort.each do |rnv_id, vol|
        puts "Putting away\t#{vol.description}"
        # puts `echo ec2-create-snapshot -d '#{vol.handle}' #{vol.volume_id}`
        p ClusterMount.from_handle(vol.handle)
      end
    end

    def detach_volumes
    end

    def ensure_volumes_are_detached
    end

    def snapshot_volumes
    end

    def delete_volumes_with_recent_snapshots
    end

    def delete_old_snapshots *args
      mounts.each do |mount|
        delete_old_snapshots *args
      end
    end

    # Hash of volumes, indexed by [role, node_idx, node_vol_idx]
    # Ex:
    #    p cluster.volumes[['master', 0, 0]]
    #    => #<struct Ec2Volume cluster="gibbon", role="master", node_idx=0, volume_idx=0, device="/dev/sdh", mount_point="/mnt/home", volume_id="vol-1cfa0475">
    def volumes
      @volumes ||= load_volumes!
    end

    #
    # interface to cluster definition from cloudera config files
    #

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
            @volumes[[role, node_idx, node_vol_idx]] =
              ClusterMount.new(name, role, node_idx, node_vol_idx, volume['device'], volume['mount_point'], volume['volume_id'])
          end
        end
      end
      @volumes
    end

  end
end

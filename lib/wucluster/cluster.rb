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
      mounts.sort.each do |mount|
        puts "Putting away\t#{mount.description}"
        # puts `echo ec2-create-snapshot -d '#{mount.handle}' #{mount.volume_id}`
        p ClusterMount.from_handle(mount.handle)
      end
    end

    def detach_volumes *args
      mounts.each do |mount|
        mount.detach!
      end
    end

    def ensure_volumes_are_detached
      20.times do
        still_attached = mounts.find_all{|mount| mount.attached?}
        if still_attached.blank? then Log.info "All mounts for the #{name} cluster are detached"; break ; end
        still_attached.each{|mount| mount.detach! }
        $stderr.puts "Wating on #{still_attached.length} nodes: #{still_attached.map(&:volume_id).inspect}"
        sleep 2
      end
    end

    def snapshots
      snaps = []
      mounts.each do |mount|
        snaps += mount.snapshots
      end
      snaps
    end

    # Ask each mount to create a snapshot of its volume, including metadata in
    # the description to make it recoverable
    def snapshot_volumes
      mounts[0..1].each do |mount|
        mount.create_snapshot
      end
    end

    def delete_volumes_with_recent_snapshots
    end

    def delete_old_snapshots *args
      mounts.each do |mount|
        mount.delete_old_snapshots *args
      end
    end

    # Hash of volumes, indexed by [role, node_idx, node_vol_idx]
    # Ex:
    #    p cluster.volumes[['master', 0, 0]]
    #    => #<struct Ec2Volume cluster="gibbon", role="master", node_idx=0, volume_idx=0, device="/dev/sdh", mount_point="/mnt/home", volume_id="vol-1cfa0475">
    def all_mounts
      @all_mounts ||= load_mounts!
    end
    # flat list of mounts
    def mounts
      all_mounts.sort.map(&:last)
    end

    #
    # interface to cluster definition from cloudera config files
    #

    # The raw cluster_role_node_volume_tree from the cloudera EC2 cluster
    # description file
    def cluster_role_node_mount_tree
      @cluster_role_node_mounts ||= JSON.load(File.open(HADOOP_EC2_DIR+"/ec2-storage-#{name}.json"))
    end

    # Turn the cluster_role_node_mount_tree into a flat list of mounts,
    # an hash indexed by [role,node_idx,node_vol_idx]
    def load_mounts!
      @all_mounts = {}
      cluster_role_node_mount_tree.each do |role, cluster_node_mounts|
        cluster_node_mounts.each_with_index do |mounts, node_idx|
          mounts.each_with_index do |mount, node_vol_idx|
            @all_mounts[[role, node_idx, node_vol_idx]] =
              ClusterMount.new(name, role, node_idx, node_vol_idx, mount['device'], mount['mount_point'], mount['volume_id'])
          end
        end
      end
      @all_mounts
    end

  end
end

module Wucluster
  class Volume

    #
    # Cluster
    #
    
    def self.new_cluster_volume cluster, cluster_vol_id,  mount_point,  size,  from_snapshot_id,  availability_zone,  device,  deletes_on_termination
      new Hash.zip(
        [:cluster, :role, :cluster_vol_id, :cluster_node_id, :mount_point, :size, :from_snapshot_id, :availability_zone, :device],
        [ cluster,  role,  cluster_vol_id,  cluster_node_id, mount_point,  size,  from_snapshot_id,  availability_zone,  device])
    end

    def availability_zone
      cluster.availability_zone if cluster
    end

    #
    # Instance
    #

    # True if instance is running
    def instance
      self.cluster.find_instance cluster_node_id
    end
    #
    def instance_running?
      instance && instance.running?
    end
    # Tell the instance to become running
    def run_instance!
      instance.run! if instance
    end

    #
    # Snapshots
    #

    # Snapshot this volume was created from.
    def from_snapshot
      Wucluster::Snapshot.find(snapshot_id)
    end

    # List all snapshots for
    def snapshots
      Wucluster::Snapshot.for_volume(self)
    end

    # List the newest snapshot (regardless of its current
    def newest_snapshot
      snapshots.sort_by(&:created_at).last
    end

    #
    def recently_snapshotted?
      newest_snapshot && newest_snapshot.recent? && newest_snapshot.completed?
    end

    def snapshotting?
      newest_snapshot && (not newest_snapshot.completed?)
    end

  end
end

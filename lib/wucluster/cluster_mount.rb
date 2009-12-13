module Wucluster

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

    def delete_old_snapshots
      Log.info "Deleting snapshots from mount point #{description}"
      # order by date
      old_snapshots = snapshots.sort_by(&:created_at)
      old_snapshots.detect!{|snapshot| snapshot.status == "completed"}
      # remove the last
      old_snapshots.pop
      old_snapshots do |snapshot|
        snapshot.delete!
      end
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
end

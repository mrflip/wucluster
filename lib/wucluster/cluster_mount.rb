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
    cattr_accessor :all
    self.all = {}
    def initialize *args
      super *args
      self.coerce_to_int!(:node_idx,   true)
      self.coerce_to_int!(:node_vol_idx, true)
      self.class.all[volume_id] = self
    end

    def delete_old_snapshots
      # order by date
      old_snapshots = snapshots.sort_by(&:created_at)
      old_snapshots = old_snapshots.find_all{|snapshot| snapshot.status == "completed"}
      # remove the last
      newest = old_snapshots.pop
      Log.info "Keeping  #{newest.description}" if newest
      old_snapshots.each do |snapshot|
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

    def self.find volume_id
      all[volume_id]
    end

    #
    # Delegate stuff to the contained volume
    #

    def volume
      Ec2Volume.find(volume_id)
    end

    def size()          volume.size          end
    def from_snapshot() volume.from_snapshot end
    def region()        volume.region        end
    def state()         volume.state         end
    def created_at()    volume.created_at    end

    def detach!()
      volume.detach! if volume
    end
    def delete_volume_if_has_recent_snapshot!
      if volume
        volume.delete_if_has_recent_snapshot!
      else
        Log.info "Skipping #{volume_id}: not in existence"
      end
    end
    def attached?()
      volume && volume.attached?
    end
    def snapshots()
      volume ? volume.snapshots : []
    end
    def newest_snapshot()
      snapshots.sort_by(&:created_at).last
    end
    def create_snapshot
      if (!volume) then Log.info "Skipping new snapshot for #{description}: no volume" ; return end
      if newest_snapshot && newest_snapshot.recent?
        Log.info "Skipping new snapshot for #{volume_id}: #{newest_snapshot.description}"
        return
      end
      volume.create_snapshot
    end
  end
end

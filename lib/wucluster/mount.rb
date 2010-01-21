module Wucluster
  class Mount
    attr_accessor :cluster
    attr_accessor :role
    attr_accessor :node_idx
    attr_accessor :node_vol_idx
    attr_accessor :device
    attr_accessor :mount_point
    attr_accessor :volume_id

    def initialize cluster, role, node_idx, node_vol_idx, device, mount_point
      self.cluster = cluster
      self.role = role
      self.node_idx = node_idx
      self.node_vol_idx = node_vol_idx
      self.device = device
      self.mount_point = mount_point
    end

    #
    # Imperatives
    #
    def instantiate!
      # if we have a volume,
      self.volume ||= Ec2Volume.new
      volume.instantiate!
    end
    def attach!
      volume.attach(node.instance)
    end
    def mount!
      node.mount(volume, mount_point)
    end
    def unmount!
      node.unmount(mount_point)
    end
    def separate!
      return if (!volume) || (volume.detached?)
      volume.detach!
    end

    def instantiated?
    end
    def attached?
    end
    def mounted?
    end
    def separated?
    end
    def recently_snapshotted?
    end
    def terminated?
    end

    # def attached?() refresh_if_dirty! ; volume.attached? ;           end
    # def detached?() refresh_if_dirty! ; volume.detached? ;           end
    # def attaching?() refresh_if_dirty! ; volume.attaching? ;         end
    # def detaching?() refresh_if_dirty! ; volume.detaching? ;         end
    # def instantiating?() refresh_if_dirty! ; volume.instantiating? ; end
    # def deleting?() refresh_if_dirty! ; volume.deleting? ;           end

    #
    # Volume Cache
    #
    def refresh_if_dirty!
      true
    end

    #
    # Snapshot
    #

    def snapshot!
      MockSnapshot.create(volume)
    end
    def last_snapshot
      MockSnapshot.get_last_snapshot(volume)
    end
    def recently_snapshotted?
      snapshot = last_snapshot
      snapshot && snapshot.recent?
    end

    # # Summary name for this volume
    # # Ex:  gibbon+master+01+00+/dev/sdh+/mnt/home+vol-1cfa0475
    # def handle
    #   [cluster, role, "%02d"%node_idx, "%02d"%node_vol_idx, device, mount_point, volume_id].join("+")
    # end
    # # readable-ish description
    # def to_s
    #   # "%-15s\tvolume for\t%15s\t%-7s\tnode #\t%7d\t%7d" % [mount_point, cluster, role, node_idx, node_vol_idx]
    #   handle.gsub(/\+/,"\t")
    # end
    # # recreate volume from handle
    # def self.from_handle handle
    #   self.new *handle.split("+", self.keys.length)
    # end
    #
    # def self.find volume_id
    #   all[volume_id]
    # end
    #
    # #
    # # Delegate stuff to the contained volume
    # #
    # def volume
    #   Ec2Volume.find(volume_id)
    # end
    #
    # def detach!()
    #   volume.detach! if volume
    # end
    # def delete_volume_if_has_recent_snapshot!
    #   if volume
    #     volume.delete_if_has_recent_snapshot!
    #   else
    #     Log.info "Skipping #{volume_id}: not in existence"
    #   end
    # end
    # def attached?()
    #   volume && volume.attached?
    # end
    # def snapshots()
    #   volume ? volume.snapshots : []
    # end
    # def newest_snapshot()
    #   snapshots.sort_by(&:created_at).last
    # end
    # def create_snapshot
    #   if (!volume) then Log.info "Skipping new snapshot for #{description}: no volume" ; return end
    #   if newest_snapshot && newest_snapshot.recent?
    #     Log.info "Skipping new snapshot for #{volume_id}: #{newest_snapshot.description}"
    #     return
    #   end
    #   volume.create_snapshot
    # end
    #
    # #
    # # Snapshot
    # #
    #
    # # Create a snapshot of the volume, including metadata in
    # # the description to make it recoverable
    # def create_snapshot options={}
    #   Log.info "Creating snapshot for #{id} as #{mount_handle}"
    #   Wucluster.ec2.create_snapshot options.merge(:volume_id => self.id, :description => mount_handle   )
    # end
    #
    # def newest_snapshot
    #   snapshots.sort_by(&:created_at).find_all(&:completed?).last
    # end
    # def has_recent_snapshot?
    #   newest_snapshot && newest_snapshot.recent?
    # end
    #
    # # List Associated Snapshots
    # def snapshots
    #   Wucluster::Ec2Snapshot.for_volume id
    # end

  end
end



    # def delete_old_snapshots
    #   # order by date
    #   old_snapshots = snapshots.sort_by(&:created_at)
    #   old_snapshots = old_snapshots.find_all{|snapshot| snapshot.to_s == "completed"}
    #   # remove the last
    #   newest = old_snapshots.pop
    #   Log.info "Keeping  #{newest.description}" if newest
    #   old_snapshots.each do |snapshot|
    #     snapshot.delete!
    #   end
    # end

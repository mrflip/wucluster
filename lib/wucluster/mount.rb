module Wucluster
  class Mount
    attr_accessor :cluster
    attr_accessor :role
    attr_accessor :node_idx
    attr_accessor :node_vol_idx
    attr_accessor :device
    attr_accessor :mount_point
    attr_accessor :volume_id
    attr_accessor :size

    def initialize cluster, role, node_idx, node_vol_idx, device, mount_point, size, volume_id
      self.cluster       = cluster
      self.role          = role
      self.node_idx      = node_idx
      self.node_vol_idx  = node_vol_idx
      self.device        = device
      self.mount_point   = mount_point
      self.size          = size
      self.volume_id     = volume_id
    end

    def id
      [cluster, role, "%03d"%node_idx, "%03d"%node_vol_idx].join("+")
    end

    def description
      [cluster, role, "%03d"%node_idx, "%03d"%node_vol_idx, device, mount_point, volume_id, size].join("+")
    end

    #
    # Imperatives
    #
    def create!
      volume = new_blank_volume if volume.nil? || volume.deleted?
      case volume.status
      when :created   then true
      when :uncreated then volume.create!
      when :deleting  then :wait
      when :creating  then :wait
      when :error     then :error
      else raise UnexpectedState, volume.status
      end
    end
    def created?
      volume && volume.created?
    end

    def attach!
      return create! unless created?
      case volume.status
      when :attached   then true
      when :detached   then volume.attach!
      when :attaching  then :wait
      when :detaching  then :wait
      when :error      then :error
      else raise UnexpectedState, volume.status
      end
    end
    def attached?
      volume && volume.attached?
    end

    def mount!
      return true    if mounted?
      return attach! unless attached?
      case
      when volume.error?    then :error
      when volume.attached? then node.mount(volume, mount_point)
      else raise UnexpectedState, "#{volume.status} - #{volume.mounted_status}"
      end
    end
    def mounted?
      volume && volume.mounted?
    end

    def unmount!
      return true    if unmounted?
      case
      when volume.error?    then :error
      when volume.mounted? then node.unmount(volume, mount_point)
      else raise UnexpectedState, "#{volume.status} - #{volume.mounted_status}"
      end
    end
    def unmounted?
      (not mounted?) && (not error?)
    end

    def separate!
      case
      when separated?        then true
      when mounted?          then unmount!
      when volume.attached?  then volume.detach!
      when volume.detaching? then :wait
      when volume.attaching? then :wait
      when volume.error?     then :error
      else raise UnexpectedState, volume.status
      end
    end
    def separated?
      (not created?) || (volume.detached?)
    end

    def snapshot!
      case
      when recently_snapshotted?  then true
      when (not created?)         then true
      when volume.snapshotting?   then :wait
      when created? && separated? then volume.snapshot!
      when (not separated?)       then separate!
      else raise UnexpectedState, volume.status
      end
    end

    def recently_snapshotted?
      volume.recently_snapshotted?
    end

    def delete!
      case
      when deleted?                     then true
      when (not separated?)             then separate!
      when (not recently_snapshotted?)  then snapshot!
      when volume.detached?             then volume.delete!
      when volume.deleting?             then :wait
      when volume.creating?             then :wait
      when volume.error?                then :error
      else raise UnexpectedState, volume.status
      end
    end
    def deleted?
      volume.uncreated?
    end

    #
    # Volume Cache
    #
    def refresh_if_dirty!
      true
    end

    def new_blank_volume
      Wucluster::Ec2Volume.new(
        :size              => size,
        :from_snapshot_id  => snapshot_id,
        :availability_zone => availability_zone,
        :device            => device
        )
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

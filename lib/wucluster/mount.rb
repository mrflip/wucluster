module Wucluster
  class Mount
    attr_accessor :cluster
    attr_accessor :role
    attr_accessor :node_idx
    attr_accessor :node_vol_idx
    attr_accessor :from_snapshot_id
    attr_accessor :device
    attr_accessor :mount_point
    attr_accessor :size
    attr_accessor :volume_id

    def initialize cluster, role, node_idx, node_vol_idx, device, mount_point, size, volume_id=nil
      self.cluster       = cluster
      self.role          = role
      self.node_idx      = node_idx
      self.node_vol_idx  = node_vol_idx
      self.device        = device
      self.mount_point   = mount_point
      self.size          = size
      self.volume_id     = volume_id
    end
    def self.from_hsh hsh
      new hsh[:cluster], hsh[:role], hsh[:node_idx], hsh[:node_vol_idx], hsh[:device], hsh[:mount_point], hsh[:size], hsh[:volume_id]
    end

    def to_s
      %Q{#<#{self.class} #{cluster.name}-#{role}-#{"%03d"%node_idx}-#{"%03d"%node_vol_idx} #{volume_id} #{size}GB #{device}~#{mount_point} #{status}>}
    end
    def inspect
      to_s
    end

    def id
      [cluster.name, role, "%03d"%node_idx, "%03d"%node_vol_idx].join("+")
    end

    def handle
      [cluster.name, role, "%03d"%node_idx, "%03d"%node_vol_idx, device, mount_point, volume_id, size].join("+")
    end

    def availability_zone
      cluster.availability_zone
    end

    def volume
      Ec2Volume.find(volume_id)
    end

    def volume=(ec2_volume)
      Log.info "Setting volume to #{ec2_volume} from #{@volume_id}"
      @volume_id = ec2_volume ? ec2_volume.id : nil
    end

    def status
      volume ? volume.status : :absent
    end
    def error?
      volume && volume.error?
    end

    def refresh!
      return self unless volume
      begin
        volume.refresh!
      rescue AWS::Error => e
        self.volume = nil if e.to_s =~ /volume.*does not exist/
      end
      self
    end

    def node
      cluster.find_node role, node_idx
    end

    #
    # Imperatives
    #
    def create!
      case
      when created?   then true
      when (volume.nil? || volume.deleted? || volume.deleting?)
        self.volume = Wucluster::Ec2Volume.create!(
          :size              => size.to_s,
          :from_snapshot_id  => from_snapshot_id,
          :availability_zone => availability_zone,
          :device            => device
          )
      when volume.creating?  then :wait
      when volume.error?     then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def created?
      volume && volume.created?
    end

    def attach!
      unless created? && node.running?
        create!
        node.run!
        return
      end
      case volume.status
      when :attached   then true
      when :detached   then volume.attach!(node.instance, device) ; :wait
      when :attaching  then :wait
      when :detaching  then :wait
      when :error      then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def attached?
      volume && volume.attached?
    end

    def mount!
      return true    if mounted?
      unless attached? then attach! ; return :wait ; end
      case
      when volume.error?    then :error
      when volume.attached? then node.mount(self)
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
      when mounted?          then unmount! ; :wait
      when volume.attached?  then volume.detach!
      when volume.detaching? then :wait
      when volume.attaching? then :wait
      when volume.error?     then :error
      else raise UnexpectedState, volume.status.to_s
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
      when (not separated?)       then separate! ; :wait
      else raise UnexpectedState, volume.status.to_s
      end
    end

    def recently_snapshotted?
      volume.recently_snapshotted?
    end

    def delete!
      case
      when ((!volume) || deleted?)      then true
      when (not separated?)             then separate! ; :wait
      when (not recently_snapshotted?)  then snapshot! ; :wait
      when volume.detached?             then volume.delete!
      when volume.deleting?             then :wait
      when volume.creating?             then :wait
      when volume.error?                then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def deleted?
      volume.nil? || volume.deleted?
    end

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
      return unless volume
      Log.info "Creating snapshot for #{self} as #{handle}"
      Wucluster::Ec2Snapshot.create! volume, handle
    end
    def newest_snapshot()
      volume && volume.newest_snapshot
    end
    def recently_snapshotted?
      volume && volume.recently_snapshotted?
    end
    # List Associated Snapshots
    def snapshots
      Wucluster::Ec2Snapshot.for_volume volume
    end

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

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
      %Q{#<#{self.class} #{cluster.name}-#{role}-#{"%03d"%node_idx}-#{"%03d"%node_vol_idx} #{volume_id} #{size}GB #{device}~#{mount_point} #{from_snapshot_id} ##{status}>}
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
    def busy?
      volume && volume.busy?
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
      when volume.busy?      then :wait
      when volume.error?     then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def created?
      volume && volume.created?
    end
    def creating?
      volume && volume.creating?
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
      when :busy       then :wait
      when :error      then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def attached?
      volume && volume.attached?
    end

    attr_reader :mounted_status

    def mount!
      return true    if mounted?
      unless attached? then attach! ; return :wait ; end
      case
      when volume.busy?     then :wait
      when volume.error?    then :error
      when volume.attached?
        Log.info "Mounting #{self}"
        # node.mount(self)
        warn "Can't 'mount #{device} #{mount_point}' yet"
        @mounted_status = true
      else raise UnexpectedState, "#{volume.status} - #{mounted_status}"
      end
    end
    def mounted?
      volume && @mounted_status
    end

    def unmount!
      return true    if unmounted?
      case
      when volume.busy?     then :wait
      when volume.error?    then :error
      when mounted?
        Log.info "Unmounting #{self}"
        # node.unmount(volume, mount_point)
        warn "Can't 'mount #{device} #{mount_point}' yet"
        @mounted_status = false
      else raise UnexpectedState, "#{volume.status} - #{mounted_status}"
      end
    end
    def unmounted?
      (not mounted?) && (not error?) && (not busy?)
    end

    def separate!
      case
      when separated?        then true
      when mounted?          then unmount! ; :wait
      when volume.attached?  then volume.detach!
      when volume.detaching? then :wait
      when volume.attaching? then :wait
      when volume.busy?      then :wait
      when volume.error?     then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def separated?
      (not created?) || (volume.detached?)
    end

    def snapshot!
      case
      when (not created?)         then true
      when volume.snapshotting?   then :wait
      when volume.recently_snapshotted? then true
      when created? && separated? then
        Wucluster::Ec2Snapshot.create! volume, handle
      when (not separated?)       then separate! ; :wait
      else raise UnexpectedState, volume.status.to_s
      end
    end

    def delete!
      case
      when ((!volume) || deleted?)      then true
      when (not separated?)             then separate! ; :wait
      when (not recently_snapshotted?)  then snapshot! ; :wait
      when volume.detached?             then volume.delete!
      when volume.deleting?             then :wait
      when volume.creating?             then :wait
      when volume.busy?                 then :wait
      when volume.error?                then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def deleted?
      volume.nil? || volume.deleted?
    end
    def deleting?
      volume && volume.deleting?
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
    # List Associated Snapshots
    def snapshots
      Wucluster::Ec2Snapshot.for_volume volume
    end

    def recently_snapshotted?
      volume && volume.recently_snapshotted?
    end

  end
end

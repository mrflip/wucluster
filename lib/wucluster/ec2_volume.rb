module Wucluster
  class Ec2Volume
    include Ec2Proxy

    # Unique ID of an EBS volume
    attr_accessor :id
    # The size of the volume, in GiBs.
    attr_accessor :size
    # Snapshot from which the volume was created (optional).
    attr_accessor :from_snapshot_id
    # Availability Zone in which the volume was created.
    attr_accessor :availability_zone
    # Volume state: creating, available, in-use, deleting, deleted, error
    attr_accessor :existence_status
    # Time stamp when volume creation was initiated.
    attr_accessor :created_at
    # AWS ID of the attached instance, if any
    attr_accessor :attached_instance_id
    # Specifies how the device is exposed to the instance (e.g., /dev/sdh).
    attr_accessor :device
    # Attachment status: attaching, attached, detaching, detached, error
    attr_accessor :attachment_status
    # Time stamp when the attachment initiated.
    attr_accessor :attached_at
    # Specifies whether the Amazon EBS volume is deleted on instance termination.
    attr_accessor :deletes_on_termination

    def to_s
      %Q{#<#{self.class} #{id} #{status} #{size}GB #{availability_zone} #{created_at} att: #{attached_instance_id} @ #{attached_at}>}
    end
    def inspect
      to_s
    end

    # @example
    #    deleted                  => :deleted
    #    deleting                 => :deleting
    #    creating                 => :creating
    #    available    nil         => :detached
    #    available    detached    => :detached
    #    in_use       attaching   => :attaching
    #    in_use       attached    => :attached
    #    in_use       detaching   => :detaching
    #    error                    => :error
    #    *            error       => :error
    def status
      # refresh! if dirty?
      return :error if (existence_status == :error) || (attachment_status == :error)
      case existence_status
      when :deleted              then :deleted
      when :creating             then :creating
      when :available
        case attachment_status
        when nil, :detached      then :detached
        when :attaching          then :attaching
        else                     raise UnexpectedState, "#{existence_status} - #{attachment_status}" end
      when :in_use
        case attachment_status
        when :attached           then :attached
        when :detaching          then :detaching
        else                     raise UnexpectedState, "#{existence_status} - #{attachment_status}" end
      when :deleting             then :deleting
      end
    end
    def deleted?()   status == :deleted   end
    def creating?()  status == :creating  end
    def created?()   [:in_use, :available].include?(existence_status) end
    def deleting?()  status == :deleting  end
    def detached?()  status == :detached  end
    def attaching?() status == :attaching end
    def attached?()  status == :attached  end
    def detaching?() status == :detaching end
    def error?()     status == :error     end
    def mounted?()   attached? && (mounted_status == :mounted) end

    def mounted_status
      false
    end
    def mount!
      raise "Can't mount yet"
    end

    #
    # Facade for EC2 API
    #

    # start creating volume
    def create! options={}
      # return if instantiating?
      Log.info "Instantiating #{self}"
      response = Wucluster.ec2.create_volume options.merge(
        :availability_zone => self.availability_zone,
        :size              => self.size,
        :snapshot_id       => self.from_snapshot_id
        )
      self.update! self.class.api_hsh_to_params(response)
      dirty!
      self
    end

    def self.create! *args
      vol = new *args
      vol.create!
      vol
    end

    # start attaching volume to its instance
    def attach! instance, device, options={}
      Log.info "Attaching #{self}"
      response = Wucluster.ec2.attach_volume options.merge( :volume_id => self.id, :instance_id => instance.id, :device => device)
      self.update! self.class.attachment_hsh_to_params(response)
      dirty!
    end
    # start removing volume from its instance
    def detach! options={}
      Log.info "Detaching #{self}"
      response = Wucluster.ec2.detach_volume options.merge(:volume_id => self.id, :instance_id => self.attached_instance_id, :device => device)
      clear_attachment_info!
      self.update! self.class.attachment_hsh_to_params(response)
      dirty!
    end
    # start deleting volume
    def delete! options={}
      return if existence_status == 'deleting'
      Log.info "Deleting #{self}"
      response = Wucluster.ec2.delete_volume options.merge(:volume_id => self.id)
      Log.warn "Request returned funky existence_status: #{response["return"]}" unless (response["return"] == "true")
      dirty!
    end

    #
    # Snapshots
    #

    # Snapshot this volume was created from.
    def from_snapshot
      Wucluster::Ec2Snapshot.find(snapshot_id)
    end

    def snapshots
      Wucluster::Ec2Snapshot.for_volume(self)
    end

    def newest_snapshot
      snapshots.sort_by(&:created_at).last
    end

    def recently_snapshotted?
      newest_snapshot && newest_snapshot.recent?
    end

    def refresh!
      clear_attachment_info!
      response = Wucluster.ec2.describe_volumes(:volume_id => id, :owner_id => Settings.aws_account_id)
      update! self.class.api_hsh_to_params(response.volumeSet.item.first)
    end

  protected
    # retrieve info for all volumes from AWS
    def self.each_api_item &block
      response = Wucluster.ec2.describe_volumes(:owner_id => Settings.aws_account_id)
      response.volumeSet.item.each(&block)
    end

    # construct instance using hash as sent back from AWS
    def self.api_hsh_to_params(api_hsh)
      hsh = {
        :id                  => api_hsh['volumeId'],
        :from_snapshot_id    => api_hsh['snapshotId'],
        :availability_zone   => api_hsh['availabilityZone'], }
      hsh[:existence_status] = api_hsh['status'].gsub(/-/,"_").to_sym if api_hsh['status']
      hsh[:size]             = api_hsh['size'].to_i if api_hsh['size']
      hsh[:created_at]       = Time.parse(api_hsh['createTime']) if api_hsh['createTime']
      attachment_hsh = api_hsh['attachmentSet']['item'].first rescue nil
      hsh.merge!( attachment_hsh_to_params(attachment_hsh) )
      hsh
    end

    def self.attachment_hsh_to_params attachment_hsh
      return {} unless attachment_hsh
      {
        :attached_at             => Time.parse(attachment_hsh['attachTime']),
        :device       => attachment_hsh['device'],
        :deletes_on_termination  => attachment_hsh['deleteOnTermination'],
        :attached_instance_id    => attachment_hsh['instanceId'],
        :attachment_status       => attachment_hsh['status'].to_sym,
      }
    end

    def clear_attachment_info!
      [:attached_at, :attached_instance_id, :attachment_status].each{|attr| self.send("#{attr}=", nil)}
    end

    def update_from_response! response
      update! self.class.api_hsh_to_params(response.volumeSet.item.first)
    end
  end
end

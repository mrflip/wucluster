module Wucluster
  class Volume

    # ===========================================================================
    #
    # Status
    #

    # Is the volume in its fully armed and operational state?
    def launched?
      mounted?
    end

    # Is the volume is completely put away?
    def put_away?
      id.nil? || deleted?
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
    #    in_use       busy        => :busy
    #    error                    => :error
    #    *            error       => :error
    def status
      # refresh! if dirty?
      return :error if (existence_status == :error) || (attachment_status == :error)
      case existence_status
      when nil                   then :deleted
      when :deleted              then :deleted
      when :creating             then :creating
      when :available
        case attachment_status
        when :detached, nil      then :detached
        when :detaching          then :detaching
        when :attaching          then :attaching
        when :busy               then :busy
        else                     raise UnexpectedState, "#{existence_status} - #{attachment_status}" end
      when :in_use
        case attachment_status
        when :attached           then :attached
        when :detaching, nil     then :detaching
        when :attaching          then :attaching
        when :busy               then :busy
        else                     raise UnexpectedState, "#{existence_status} - #{attachment_status}" end
      when :deleting             then :deleting
      else
        raise "WTF, I don't understand my status: #{existence_status} - #{attachment_status}"
      end
    end
    def deleted?()   status == :deleted   end
    def deleting?()  status == :deleting  end
    def creating?()  status == :creating  end
    def created?()   [:in_use, :available].include?(existence_status) end
    def detached?()  status == :detached  end
    def detaching?() status == :detaching end
    def attaching?() status == :attaching end
    def attached?()  status == :attached  end
    def busy?()      status == :busy      end
    def error?()     status == :error     end
    def mounted?
      attached? && (@mounted_status == :mounted)
    end
    def unmounted?
      (not attached?) || @mounted_status.nil? || (@mounted_status == :unmounted)
    end
    # override if you don't want to allow volumes to be unmounted at any time
    def unmountable?
      true
    end

    # ===========================================================================
    #
    # Commands
    #

    # Fetch current state from remote API
    def refresh!
      clear_attachment_info!
      response = Wucluster.ec2.describe_volumes(:volume_id => id, :owner_id => Settings.aws_account_id)
      update! self.class.api_hsh_to_params(response.volumeSet.item.first)
    end

    # update internal state using a full api response
    def update! *args
      clear_attachment_info!
      super(*args)
    end

    # the attributes that come from AWS api, describe its concrete representation
    def ec2_attributes
      to_hash.slice(
        :id, :size, :from_snapshot_id,
        :availability_zone, :device, :deletes_on_termination,
        :existence_status, :created_at, :attached_instance_id,
        :attachment_status, :attached_at
        )
    end

    # the attributes that come from AWS api, describe its concrete representation
    def logical_attributes
      to_hash.slice( :cluster, :cluster_vol_id, :cluster_node_id, :mount_point )
    end

  protected

    # start creating volume
    def start_creating! options={}
      return :wait if creating? || created? || busy?
      Log.info "Creating #{self}"
      response = Wucluster.ec2.create_volume options.merge(
        :availability_zone => self.availability_zone,
        :size              => self.size.to_s,
        :snapshot_id       => self.from_snapshot_id
        )
      Log.debug response
      self.update! self.class.api_hsh_to_params(response)
      self.class.register self
      self
    end

    # make a new volume proxy and create it on the remote end
    def self.start_creating! hsh
      vol = new hsh
      vol.create!
      vol
    end

    # start attaching volume to its instance
    def start_attaching! options={}
      return :wait if attaching? || attached? || busy?
      Log.info "Attaching #{self} to #{instance} as #{device}"
      response = Wucluster.ec2.attach_volume options.merge( :volume_id => self.id, :instance_id => instance.id, :device => device)
      Log.debug response
      self.update! self.class.attachment_hsh_to_params(response)
    end

    # start removing volume from its instance
    def start_detaching! options={}
      return :wait if detaching? || detached? || busy?
      Log.info "Detaching #{self} from #{attached_instance_id}"
      response = Wucluster.ec2.detach_volume options.merge(:volume_id => self.id, :instance_id => self.attached_instance_id, :device => device)
      Log.debug response
      clear_attachment_info!
      self.update! self.class.attachment_hsh_to_params(response)
      dirty!
    end

    # start deleting volume
    def start_deleting! options={}
      return :wait if deleting? || deleted? || busy?
      Log.info "Deleting #{self}"
      response = Wucluster.ec2.delete_volume options.merge(:volume_id => self.id)
      Log.debug response
      Log.warn "Request returned funky existence_status: #{response["return"]}" unless (response["return"] == "true")
      dirty!
    end

    # request to the instance that the volume be mounted
    def start_mounting!
      @mounted_status = instance.mount! self
    end

    # request to the instance that the volume be unmounted
    def start_unmounting!
      @mounted_status = instance.unmount! self
    end

    # ===========================================================================
    #
    # Low-level munging of AWS API responses
    #

    # retrieve info for all volumes from AWS
    def self.each_api_item &block
      response = Wucluster.ec2.describe_volumes(:owner_id => Settings.aws_account_id)
      response.volumeSet.item.each(&block)
    end

    # construct instance using hash as sent back from AWS
    def self.api_hsh_to_params(api_hsh)
      # Log.debug api_hsh.inspect
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

    # convert params for the attachment segment of aws api responses
    def self.attachment_hsh_to_params attachment_hsh
      return {} unless attachment_hsh
      {
        :attached_at             => Time.parse(attachment_hsh['attachTime']),
        :device                  => attachment_hsh['device'],
        :deletes_on_termination  => attachment_hsh['deleteOnTermination'],
        :attached_instance_id    => attachment_hsh['instanceId'],
        :attachment_status       => attachment_hsh['status'].to_sym,
      }
    end

    # clear the attachment segment of the internal state
    def clear_attachment_info!
      [:attached_at, :attached_instance_id, :attachment_status
      ].each{|attr| self.send("#{attr}=", nil)}
    end
  end
end

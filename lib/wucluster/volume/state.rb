module Wucluster
  class Volume

    # ===========================================================================
    #
    # Status
    #

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
      when :deleted              then :deleted
      when :creating             then :creating
      when :available
        case attachment_status
        when nil, :detached      then :detached
        when :detaching          then :detaching
        when :attaching          then :attaching
        when :busy               then :busy
        else                     raise UnexpectedState, "#{existence_status} - #{attachment_status}" end
      when :in_use
        case attachment_status
        when :attached           then :attached
        when :detaching          then :detaching
        when :attaching          then :attaching
        when :busy               then :busy
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
    def busy?()      status == :busy      end
    def error?()     status == :error     end
    def mounted?()   attached? && (mounted_status == :mounted) end

    #
    # Facade for EC2 API
    #

    # start creating volume
    def create! options={}
      return :wait if creating? || created?
      Log.info "Creating #{self}"
      response = Wucluster.ec2.create_volume options.merge(
        :availability_zone => self.availability_zone,
        :size              => self.size,
        :snapshot_id       => self.from_snapshot_id
        )
      Log.debug response
      self.update! self.class.api_hsh_to_params(response)
      self.class.register self
      self
    end

    # make a new volume proxy and create it on the remote end
    def self.create! hsh
      vol = new hsh
      vol.create!
      vol
    end

    # start attaching volume to its instance
    def attach! instance, device, options={}
      return :wait if attaching? || attached?
      Log.info "Attaching #{self} to #{instance} as #{device}"
      response = Wucluster.ec2.attach_volume options.merge( :volume_id => self.id, :instance_id => instance.id, :device => device)
      Log.debug response
      self.update! self.class.attachment_hsh_to_params(response)
    end

    # start removing volume from its instance
    def detach! options={}
      return :wait if detaching? || detached?
      Log.info "Detaching #{self} from #{attached_instance_id}"
      response = Wucluster.ec2.detach_volume options.merge(:volume_id => self.id, :instance_id => self.attached_instance_id, :device => device)
      Log.debug response
      clear_attachment_info!
      self.update! self.class.attachment_hsh_to_params(response)
      dirty!
    end

    # start deleting volume
    def delete! options={}
      return :wait if deleting? || deleted?
      Log.info "Deleting #{self}"
      response = Wucluster.ec2.delete_volume options.merge(:volume_id => self.id)
      Log.debug response
      Log.warn "Request returned funky existence_status: #{response["return"]}" unless (response["return"] == "true")
      dirty!
    end

  end
end

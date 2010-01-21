require 'wucluster/ec2_volume/api'
module Wucluster
  class Ec2Volume
    # Unique ID of an EBS volume
    attr_accessor :id
    # The size of the volume, in GiBs.
    attr_accessor :size
    # Snapshot from which the volume was created (optional).
    attr_accessor :from_snapshot_id
    # Availability Zone in which the volume was created.
    attr_accessor :availability_zone
    # Volume state: creating, available, in-use, deleting, deleted, error
    attr_accessor :status
    # Time stamp when volume creation was initiated.
    attr_accessor :created_at
    # AWS ID of the attached instance, if any
    attr_accessor :attached_instance_id
    # Specifies how the device is exposed to the instance (e.g., /dev/sdh).
    attr_accessor :attachment_device
    # Attachment status: attaching, attached, detaching, detached, error
    attr_accessor :attachment_status
    # Time stamp when the attachment initiated.
    attr_accessor :attached_at
    # Specifies whether the Amazon EBS volume is deleted on instance termination.
    attr_accessor :deletes_on_termination

    def initialize id = nil
      self.id = id
      self.refresh!
    end

    # Ec2Snapshot this volume was created from
    attr_reader :from_snapshot
    # :nodoc:
    def from_snapshot_id= snapshot_id
      @from_snapshot_id = snapshot_id
      @from_snapshot    = ::Wucluster::Ec2Snapshot.find(snapshot_id)
    end

    #
    # Facade for EC2 API
    #

    def instantiate! options={}
      return if instantiating?
      Log.info "Instantiating #{self}"
      Wucluster.ec2.create_volume options.reverse_merge(
        :availability_zone => self.availability_zone,
        :size              => self.size,
        :snapshot_id       => self.from_snapshot_id
        )
    end
    # attaches volume to its instance
    def attach! options={}
      return if attached?
      Log.info "Attaching #{self}"
      Wucluster.ec2.attach_volume options.reverse_merge(
        :volume_id => self.id, :instance_id => '', :device => '')
    end
    # removes volume from its instance
    def detach! options={}
      return if detached?
      Log.info "Detaching #{self}"
      Wucluster.ec2.detach_volume options.reverse_merge(:force => false,
        :volume_id => self.id, :instance_id => '', :device => '')
    end
    def delete! options={}
      return if deleting?
      Log.info "Deleting #{self}"
      Wucluster.ec2.delete_volume options.reverse_merge(:volume_id => self.id)
    end

    # #
    # # Statuses
    # #
    #
    # def instantiating?
    #   status == :instantiating
    # end
    # def instantiated?
    #   status == :available
    # end
    # def deleting?
    #   [:deleting].include?(status)
    # end
    # def attaching?
    # end
    # def attached?
    #   instantiated? && (! attached_instance.blank?)
    # end
    # def detached?
    #   [:available, :deleting].include?(status) &&
    #     attached_instance.blank?
    # end
    # def detaching?
    # end

  end
end

require 'wucluster/ec2_volume/api'
module Wucluster
  class Ec2Volume
    # Unique ID of an EBS volume
    attr_accessor :id
    # Size in
    attr_accessor :size
    #
    attr_accessor :from_snapshot_id
    #
    attr_accessor :zone
    #
    attr_accessor :status
    #
    attr_accessor :created_at
    #
    attr_accessor :attached_instance
    #
    attr_accessor :attachment_device
    #
    attr_accessor :attachment_status
    #
    attr_accessor :attached_at
    #
    attr_accessor :deletes_on_termination

    def initialize id = nil
      self.id = id
      self.refresh!
    end

    # def to_s
    #   "#{id}: #{[attached_instance, status].inspect}"
    # end

    #
    # Facade for EC2 API
    #

    def instantiate! options={}
      return if instantiating?
      Log.info "Instantiating #{self}"
      Wucluster.ec2.create_volume options.reverse_merge(
        :availability_zone => '',
        :size => '',
        :snapshot_id => ''
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

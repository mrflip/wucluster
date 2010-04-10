require 'wucluster/volume/ec2'
require 'wucluster/volume/components'
module Wucluster
  #
  # Wucluster::Volume is a facade for the EC2 ruby API --
  #
  # * you can treat the volume as a logical entity: specifying the properties
  #   of a volume that doesn't yet exist remotely
  #
  class Volume
    include Ec2Proxy
    include DependencyGraph

    #
    # Attributes
    #

    # Volume's meta-attributes, defined by the cluster

    # Cluster this volume belongs to
    attr_accessor :cluster_name
    # cluster identifier for this volume
    attr_accessor :cluster_vol_id
    # cluster identifier for instance it will attach to
    attr_accessor :cluster_node_id
    # cluster identifier for instance it will attach to
    attr_accessor :cluster_vol_index
    # mount path for volume
    attr_accessor :mount_point

    # These attributes define the volume for AWS

    # Unique ID of an EBS volume
    attr_accessor :id
    # The size of the volume, in GiBs.
    attr_accessor :size
    # Snapshot from which the volume was created (optional).
    attr_accessor :from_snapshot_id
    # Availability Zone in which the volume was created.
    attr_accessor :availability_zone
    # Specifies how the device is exposed to the instance (e.g., /dev/sdh).
    attr_accessor :device
    # Specifies whether the Amazon EBS volume is deleted on instance termination.
    attr_accessor :deletes_on_termination

    # These attributes are under AWS' control

    # Volume state: creating, available, in-use, deleting, deleted, error
    attr_accessor :existence_status
    # Time stamp when volume creation was initiated.
    attr_accessor :created_at
    # AWS ID of the attached instance, if any
    attr_accessor :attached_instance_id
    # Attachment status: attaching, attached, detaching, detached, error
    attr_accessor :attachment_status
    # Time stamp when the attachment initiated.
    attr_accessor :attached_at

    # availability_zone, either as set from concrete manifestation or (else) as
    # logically defined by cluster.
    def availability_zone
      @availability_zone || (cluster && cluster.availability_zone)
    end

    #
    # Actions to take for volume
    #

    # Become fully created, attached, mounted
    def launch!
      mount!
    end
    def launched?
      mounted?
    end

    # Become fully unmounted, detached, snapshotted, deleted,
    def put_away!
      delete!
    end
    def put_away?
      status.nil? || deleted? || deleting?
    end

    def create!()   self.become :created?     end
    def attach!()   self.become :attached?    end
    def mount!()    self.become :mounted?     end
    def unmount!()  self.become :unmounted?   end
    def detach!()   self.become :detached?    end
    def delete!()   self.become :deleted?     end
    def snapshot!() self.become :recently_snapshotted? end

    #
    # State diagram for volume setup and teardown
    #

    cattr_accessor :volume_graph
    self.volume_graph = [
      # goal                  precondition            next_action
      [:put_away?,              nil,                   nil],
      [:creating?,             :put_away?,            :start_creating!],
      [:created?,              :creating?,            :wait],
      #
      [:attaching?,           [:created?,  :instance_running?], :start_attaching!],
      [:attached?,             :attaching?,           :wait],
      [:mounted?,              :attached?,            :start_mounting!],
      [:launched?,            :mounted?,             nil],
      #
      [:unmounted?,            :unmountable?,         :start_unmounting!],
      [:detaching?,            :unmounted?,           :start_detaching!],
      [:detached?,             :detaching?,           :wait],
      [:deleting?,            [:detached?, :recently_snapshotted?], :start_deleting!],
      [:deleted?,              :deleting?,            :wait],
      #
      [:snapshotting?,         :detached?,            :start_snapshotting!],
      [:recently_snapshotted?, :snapshotting?,        :wait],
      [:instance_running?,     nil,                   :run_instance!]
    ]
    # FIXME -- make a mattr_whatever
    def dependencies
      volume_graph
    end

    def to_s
      %Q{#<#{self.class} #{id} #{status} #{size}GB #{availability_zone} #{created_at} #{cluster_name} att: #{attached_instance_id} @ #{attached_at} #{mount_point} #{device} >}
    end
    def inspect() to_s end
    def to_hash
      %w[ cluster_name cluster_vol_id cluster_node_id mount_point id size from_snapshot_id
          availability_zone device deletes_on_termination
          existence_status created_at attached_instance_id attachment_status attached_at
        ].inject({}){|hsh, attr| hsh[attr.to_sym] = self.send(attr); hsh}
    end
    def handle
      [cluster_name, cluster_node_id, cluster_vol_id, cluster_vol_index, device, mount_point].join("+")
    end
  end
end

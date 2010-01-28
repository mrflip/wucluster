module Wucluster
  class Volume
    require 'wucluster/volume/ec2'
    require 'wucluster/volume/has_snapshots'
    require 'wucluster/volume/has_instances'
    require 'wucluster/volume/state'
    include Ec2Proxy
    include DependencyGraph
    #
    # State diagram for volume setup and teardown
    #

    cattr_accessor :volume_graph
    self.volume_graph = [
      [:away?,                 nil,                   nil],                     
      [:creating?,             :away?,                :create!],                
      [:created?,              :creating?,            :wait],                   
      # [:node_running?,       nil,                   :run_node!],             
      [:attaching?,           [:created?,  :node_running?], :attach!],         
      [:attached?,             :attaching?,           :wait],                   
      [:mounted?,              :attached?,            :mount!],                 
      [:completed?,            :mounted?,             nil],                     
      #                                                                         
      [:unmounted?,            :unmountable?,         :unmount!],
      [:detaching?,            :unmounted?,           :separate!],              
      [:detached?,             :detaching?,           :wait],                   
      [:deleting?,            [:detached?, :recently_snapshotted?], :delete!], 
      [:deleted?,              :deleting?,            :wait],                   
      #
      [:snapshotting?,         :detached?,            :snapshot!],
      [:recently_snapshotted?, :snapshotting?,        :wait],
    ]
    # FIXME -- make a mattr_whatever
    def dependencies
      volume_graph
    end

    #
    # Attributes
    #

    # Volume's meta-attributes, defined by the cluster
    
    # Cluster this volume belongs to
    attr_accessor :cluster
    # cluster identifier for this volume
    attr_accessor :cluster_vol_id
    # cluster identifier for instance it will attach to
    attr_accessor :cluster_node_id
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

    def self.new_cluster_volume cluster, cluster_vol_id,  mount_point,  size,  from_snapshot_id,  availability_zone,  device,  deletes_on_termination
      new Hash.zip(
        [:cluster, :role, :cluster_vol_id, :cluster_node_id, :mount_point, :size, :from_snapshot_id, :availability_zone, :device],
        [ cluster,  role,  cluster_vol_id,  cluster_node_id, mount_point,  size,  from_snapshot_id,  availability_zone,  device])
    end

    def to_s
      %Q{#<#{self.class} #{id} #{status} #{size}GB #{availability_zone} #{created_at} att: #{attached_instance_id} @ #{attached_at}>}
    end
    def inspect
      to_s
    end
    def to_hash
      %w[ cluster cluster_vol_id cluster_node_id mount_point id size from_snapshot_id
          availability_zone device deletes_on_termination
          existence_status created_at attached_instance_id attachment_status attached_at
        ].inject({}){|hsh, attr| hsh[attr.to_sym] = self.send(attr); hsh}
    end
    def handle
      [cluster.name, cluster_node_id, device, mount_point, volume_id, size].join("+")
    end
    def instance
      Cluster.find_instance cluster_node_id
    end
  end
end

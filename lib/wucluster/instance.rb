require 'wucluster/instance/api'
module Wucluster
  class Instance
    include Ec2Proxy

    # Instance's meta-attributes, defined by the cluster

    # Cluster this volume belongs to
    attr_accessor :cluster
    # string identifying logical role
    attr_accessor :role
    # identifier for this node within the cluster -- distinct from the AWS
    # instance ID, this uniquely specifies the instance within the cluster
    # itself.
    attr_accessor :cluster_node_id
    # mount path for volume
    attr_accessor :mount_point

    # Unique ID of a machine image.
    attr_accessor :id
    # instance status: pending, running, shutting-down, terminated, stopping, stopped
    attr_accessor :status
    # The name of the AWS key pair, used for remote access to instance
    attr_accessor :key_name
    # Name of the security group. Act as both logical labels for the instance
    # and define its security policy
    attr_accessor :security_groups
    # Placement constraints (Availability Zones) for launching the instances.
    attr_accessor :availability_zone
    # Size of the instance to launch (m1.small | m1.large | m1.xlarge | c1.medium | c1.xlarge | m2.2xlarge | m2.4xlarge)
    attr_accessor :instance_type
    # IP address of the internal interface
    attr_accessor :private_ip
    # IP address of the external interface
    attr_accessor :public_ip
    # Instance launch time. The time the instance launched
    attr_accessor :created_at
    # AWS' AMI id for the machine image to use
    attr_accessor :image_id

    node_graph = [
      [:away?, nil, nil],
      [:pending?,      :away?,                        :run!],
      [:running?,       :pending?,                    :wait],
      [:completed?,      :created?,                     nil],
      #
      [:terminateable?, [:volumes_detached?,], :detach_volumes!],
      [:terminating?,   :terminateable?,  :terminate!],
      [:terminated, :terminating?, :wait],
    ]

    def self.new_cluster_instance cluster, role, cluster_node_id, image_id, instance_type
      new Hash.zip(
        [:cluster, :role, :cluster_node_id, :image_id, :instance_type],
        [ cluster,  role,  cluster_node_id,  image_id,  instance_type])
    end

    def to_s
      %Q{#<#{self.class} #{id} #{status} #{key_name} #{security_groups.inspect} #{public_ip} #{private_ip} #{created_at} #{instance_type} #{availability_zone} #{image_id}>}
    end
    def inspect
      to_s
    end
    def to_hash
      %w[id status key_name security_groups availability_zone instance_type public_ip private_ip created_at image_id
        ].inject({}){|hsh, attr| hsh[attr.to_sym] = self.send(attr); hsh}
    end
  end
end

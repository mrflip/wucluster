require 'wucluster/instance/api'
module Wucluster
  class Instance
    include Ec2Proxy
    include DependencyGraph

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

    NODE_GRAPH = [
      [:away?, nil, nil],
      [:pending?,      :away?,                        :run!],
      [:running?,       :pending?,                    :wait],
      [:launched?,      :running?,                     nil],
      #
      [:post_launched?, nil, nil],
      [:volumes_detached?, :post_launched?, :detach_volumes!],
      [:terminateable?, [:volumes_detached?,], nil],
      [:terminating?,   :terminateable?,  :terminate!],
      [:terminated?, :terminating?, :wait],
    ]
    def dependencies
      Wucluster::Instance::NODE_GRAPH
    end

    def away?
      id.nil? || deleted?
    end

    # hooks for anything that would prevent a running server from terminating
    def terminateable?
      puts "Test for terminable" ; true
    end
    def detach_volumes!
      puts "Can't detach volumes yet"
    end
    def volumes_detached?
      puts "Test for detach volumes" ; true
    end

    def launched?
      running?
    end

    # Name of the security group. Act as both logical labels for the instance
    # and define its security policy
    #
    # The nodes label themselves with cluster name and with cluster.name-role
    #
    # @example
    #   cluster = Cluster.new :bonobo
    #   Node.new cluster, :master, 0,
    def security_groups
      [cluster.name.to_s, "#{cluster.name}-#{role}", cluster_node_id]
    end

    # The name of the AWS key pair, used for remote access to instance
    def key_name
      cluster.name.to_s
    end

    # Placement constraints (Availability Zones) for launching the instances.
    def availability_zone
      cluster.availability_zone
    end

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

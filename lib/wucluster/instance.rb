require 'wucluster/instance/ec2'
require 'wucluster/instance/components'
module Wucluster
  class Instance
    include Ec2Proxy
    include DependencyGraph

    # Instance's meta-attributes, defined by the cluster

    # Cluster this volume belongs to
    attr_accessor :cluster
    # string identifying logical role
    attr_accessor :role
    # identifier for this instance within the cluster -- distinct from the AWS
    # instance ID, this uniquely specifies the instance within the cluster
    # itself.
    attr_accessor :cluster_node_id

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

    def to_hash
      %w[
        cluster role cluster_node_id
        id status key_name security_groups availability_zone instance_type public_ip private_ip created_at image_id
        ].inject({}){|hsh, attr| hsh[attr.to_sym] = self.send(attr); hsh}
    end
    def cluster_node_index
      cluster_node_id.split(/-/).last
    end

    #
    # Virtual attribute defaults
    #

    # Name of the security group. Act as both logical labels for the instance
    # and define its security policy
    #
    # The nodes label themselves with cluster name and with cluster.name-role
    #
    # @example
    #   cluster = Cluster.new :bonobo
    #   Node.new cluster, :master, 0,
    def security_groups
      @security_groups || logical_security_groups
    end

    # The name of the AWS key pair, used for remote access to instance
    def key_name
      @key_name || cluster.name.to_s
    end

    # Placement constraints (Availability Zones) for launching the instances.
    def availability_zone
      @availability_zone || cluster.availability_zone
    end

    #
    # Actions to take for volume
    #

    # Become fully created, attached, mounted
    def launch!
      run!
    end
    def launched?
      running?
    end

    # Become fully unmounted, detached, snapshotted, deleted,
    def put_away!
      terminate!
    end
    def put_away?
      terminated?
    end

    def run!()       self.become :running?     end
    def terminate!() self.become :terminated?  end

    NODE_GRAPH = [
      [:away?, nil, nil],
      [:pending?,          :away?,               :start_running!],
      [:running?,          :pending?,            :wait],
      [:launched?,         :running?,            nil],
      #
      [:post_launched?,    nil, nil],
      [:volumes_detached?, :post_launched?,      :detach_volumes!],
      [:terminateable?,   [:volumes_detached?,], nil],
      [:terminating?,      :terminateable?,      :start_terminating!],
      [:terminated?,       :terminating?,        :wait],
    ]
    def dependencies
      Wucluster::Instance::NODE_GRAPH
    end

    def to_s
      %Q{#<#{self.class} #{id} #{status} #{key_name} #{security_groups.inspect} #{public_ip} #{private_ip} #{created_at} #{instance_type} #{availability_zone} #{image_id}>}
    end
    def inspect
      to_s
    end
  end
end

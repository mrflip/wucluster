
# ===========================================================================
#
# Components
#
# The instance's cluster and its component volumes, security_groups, keypairs

module Wucluster
  class Instance

    #
    # Cluster
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

    # Security groups defined by cluster structure
    def logical_security_groups
      @security_groups = [cluster.name.to_s, "#{cluster.name}-#{role}", cluster_node_id]
    end

    # The name of the AWS key pair, used for remote access to instance
    def key_name
      @key_name || cluster.name.to_s
    end

    # Placement constraints (Availability Zones) for launching the instances.
    def availability_zone
      @availability_zone || cluster.availability_zone
    end

    # Builds a logical instance object (disconnected from any running instance
    # that might exist)
    def self.new_cluster_instance cluster, role, cluster_node_id, image_id, instance_type
      new Hash.zip(
        [:cluster, :role, :cluster_node_id, :image_id, :instance_type],
        [ cluster,  role,  cluster_node_id,  image_id,  instance_type])
    end

    # Uniquely identifies this instance's role within the cluster
    def get_cluster_node_id cluster_name
      security_groups.                            # grab security groups
        find_all{|sg| sg =~ /^#{cluster_name}-/}. # describing the cluster-role-#
        sort.last                                 # and take the most specific
    end

    #
    # Volume
    #

    # remotely issues the command to mount the given volume
    #
    # @param volume [Wucluster::Volume] the volume to mount
    #
    # @return :mounted if successful
    def mount! volume
      puts "Can't mount volumes yet (#{volume})"
      return :mounted
    end
    # remotely issues the command to unmount the given volume
    #
    # @param volume [Wucluster::Volume] the volume to unmount
    #
    # @return :mounted if successful
    def unmount! volume
      puts "Can't unmount volumes yet (#{volume})"
      return :unmounted
    end

  end
end

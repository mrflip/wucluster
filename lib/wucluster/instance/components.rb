
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

    # Security groups defined by cluster structure
    def logical_security_groups
      @security_groups = [cluster.name.to_s, "#{cluster.name}-#{role}", cluster_node_id]
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
    def volumes
      return nil unless cluster
      cluster.volumes.find { |vol| vol.cluster_node_id == cluster_node_id }
    end

    # remotely issues the command to mount the given volume
    #
    # @param volume [Wucluster::Volume] the volume to mount
    #
    # @return :mounted if successful
    def mount! volume
      return :mounted if successful_remote_command?("mount #{volume.device} #{volume.mount_point}")
    end
    # remotely issues the command to unmount the given volume
    #
    # @param volume [Wucluster::Volume] the volume to unmount
    #
    # @return :unmounted if successful
    def unmount! volume
      return :unmounted if successful_remote_command?("umount #{volume.device}")
    end

  end
end

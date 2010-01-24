module Wucluster
  class Cluster

    #
    # Bookkeeping of nodes and mounts
    #

    # Hash of mounts, indexed by [role, node_idx, node_vol_idx]
    # Ex:
    #    p cluster.mounts[['master', 0, 0]]
    #    => #<struct Wucluster::Mount cluster="gibbon", role="master", node=<Wucluster::Node ...>, mount_idx=0, device="/dev/sdh", mount_point="/mnt/home", volume=#<Wucluster::Ec2Volume ...> >
    def all_mounts
      load! if @all_mounts.nil?
      @all_mounts
    end
    # flat list of mounts
    def mounts
      all_mounts.sort_by(&:first).map(&:last)
    end
    # Mount with the given role and index
    def find_mount role, idx
      all_mounts[ [role, idx] ]
    end

    # Hash of nodes, indexed by [role, node_idx]
    # Ex:
    #    p cluster.nodes[['master', 0, 0]]
    #    => #<struct Wucluster::Node cluster="gibbon", role="master", idx=0, node=...>
    def all_nodes
      load! if @all_nodes.nil?
      @all_nodes
    end
    # flat list of nodes
    def nodes
      all_nodes.sort_by(&:first).map(&:last)
    end
    # Node with the given role and index
    def find_node role, idx
      all_nodes[ [role, idx] ]
    end

    # flat list of snapshots from all mounts
    def snapshots
      Ec2Volume::Snapshot.all.find_all{|snap| }
    end

    # Turn the cluster_role_node_mount_tree into a flat list of mounts,
    # an hash indexed by [role,node_idx,node_vol_idx]
    # interface to cluster definition from cloudera config files
    def load!
      @all_mounts = {}
      @all_nodes  = {}
      cluster_cfg = cluster_definition_from_config
      load_attrs_from_cfg cluster_cfg
      cluster_cfg[:nodes].each do |role, nodes_for_role|
        role = role.to_s
        nodes_for_role.each_with_index do |node_cfg, node_idx|
          load_node_cfg role, node_idx, node_cfg
        end
      end
      self
    end

    def load_attrs_from_cfg cluster_cfg
      self.availability_zone = cluster_cfg[:availability_zone] if cluster_cfg[:availability_zone]
      self.image_id          = cluster_cfg[:image_id]          if cluster_cfg[:image_id]
      self.instance_type     = cluster_cfg[:instance_type]     if cluster_cfg[:instance_type]
    end

    def load_node_cfg role, node_idx, node_cfg
      instance_type = node_cfg[:instance_type] || self.instance_type
      image_id      = node_cfg[:image_id]      || self.image_id
      @all_nodes[ [role, node_idx] ] = Node.new(self, role, node_idx, image_id, instance_type)
      if node_cfg[:mounts]
        node_cfg[:mounts].each_with_index do |mount_cfg, node_vol_idx|
          load_mount_cfg(role, node_idx, node_vol_idx, mount_cfg)
        end
      end
    end

    def load_mount_cfg role, node_idx, node_vol_idx, mount_cfg
      @all_mounts[[role, node_idx, node_vol_idx]] =
        Mount.new(self, role, node_idx, node_vol_idx, mount_cfg[:device], mount_cfg[:mount_point], mount_cfg[:size], mount_cfg[:volume_id])
    end

    def catalog_existing
      Ec2Volume.all
      # @all_mounts[[role, node_idx, node_vol_idx]] =
      #   Mount.new(cluster, role, node_idx, node_vol_idx, vol.device, vol.mount_point, vol.size, vol.id)
    end

  protected

    def cluster_definition_from_config
      Settings.clusters[name]
    end

  end
end

# protected
#
# # Turn the cluster_role_node_mount_tree into a flat list of mounts,
# # an hash indexed by [role,node_idx,node_vol_idx]
# # interface to cluster definition from cloudera config files
# def load_from_cloudera_file!
#   @all_mounts = {}
#   @all_nodes  = {}
#   cluster_role_node_mount_tree.each do |role, cluster_node_mounts|
#     role = role
#     cluster_node_mounts.each_with_index do |mounts, node_idx|
#       image_id = 'ami-0b02e162' ; instance_type = 'm1.small'
#       @all_nodes[ [role, node_idx] ] = Node.new self, role, node_idx, image_id, instance_type
#       mounts.each_with_index do |mount, node_vol_idx|
#         @all_mounts[[role, node_idx, node_vol_idx]] =
#           Mount.new(self, role, node_idx, node_vol_idx, mount['device'], mount['mount_point'], mount['volume_id'])
#       end
#     end
#   end
#   @all_mounts
# end
#
# # The raw cluster_role_node_volume_tree from the cloudera EC2 cluster file
# def cluster_definition_from_cloudera_file
#   JSON.load(File.open(Settings.cluster_definition_dir + "/ec2-storage-#{name}.json"))
# end

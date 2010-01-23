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
      @all_mounts ||= load_description!
    end
    # flat list of mounts
    def mounts
      all_mounts.sort.map(&:last)
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
      @all_nodes ||= load_description!
    end
    # flat list of nodes
    def nodes
      all_nodes.map(&:last)
    end
    # Node with the given role and index
    def find_node role, idx
      all_nodes[ [role, idx] ]
    end

    # flat list of snapshots from all mounts
    def snapshots
      snaps = []
      mounts.each do |mount|
        snaps += mount.snapshots
      end
      snaps
    end

    # Turn the cluster_role_node_mount_tree into a flat list of mounts,
    # an hash indexed by [role,node_idx,node_vol_idx]
    # interface to cluster definition from cloudera config files
    def load_description!
      @all_mounts = {}
      @all_nodes  = {}
      cluster_role_node_mount_tree.each do |role, cluster_node_mounts|
        role = role.to_sym
        cluster_node_mounts.each_with_index do |mounts, node_idx|
          image_id = 'ami-0b02e162' ; instance_type = 'm1.small'
          @all_nodes[ [role, node_idx] ] = Node.new self, role, node_idx, image_id, instance_type
          mounts.each_with_index do |mount, node_vol_idx|
            @all_mounts[[role, node_idx, node_vol_idx]] =
              Mount.new(self, role, node_idx, node_vol_idx, mount['device'], mount['mount_point'], mount['volume_id'])
          end
        end
      end
      @all_mounts
    end

  protected
    # The raw cluster_role_node_volume_tree from the cloudera EC2 cluster file
    def cluster_role_node_mount_tree
      @cluster_role_node_mounts ||= JSON.load(File.open(Settings.cluster_definition_dir + "/ec2-storage-#{name}.json"))
    end
  end
end

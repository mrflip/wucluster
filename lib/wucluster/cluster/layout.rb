module Wucluster
  class Cluster

  protected
    # grab layout tree from config settings
    def cluster_config
      Settings.clusters[name]
    end

    # The cluster config is a tree
    # describing for each role,
    # => the instances serving in that role
    #    => and the volumes attached to those instances
    # 
    def load_layout
      return unless cluster_config
      @all_volumes    = {}
      @all_instances  = {}
      load_attrs
      load_instances_and_volumes
    end

    def load_attrs 
      self.availability_zone      = cluster_config[:availability_zone]      if cluster_config[:availability_zone]
      self.image_id               = cluster_config[:image_id]               if cluster_config[:image_id]
      self.instance_type          = cluster_config[:instance_type]          if cluster_config[:instance_type]
      # self.deletes_on_termination = cluster_config[:deletes_on_termination] if cluster_config[:deletes_on_termination]
    end

    def load_instances_and_volumes
      cluster_instances = cluster_config[:instances] or return
      cluster_instances.each do |role, instances_for_role|
        role = role.to_s
        instances_for_role.each_with_index do |instance_cfg, instance_idx|
          load_instance role, instance_idx, instance_cfg
        end
      end      
    end
    
    def load_instance role, instance_idx, instance_cfg
      instance_type   = instance_cfg[:instance_type] || self.instance_type
      image_id        = instance_cfg[:image_id]      || self.image_id
      cluster_node_id = [self.name, role, "%03d"%instance_idx].join('-')
      @all_instances[cluster_node_id] = Instance.new_cluster_instance(self, role, cluster_node_id, image_id, instance_type)
      if instance_cfg[:volumes]
        instance_cfg[:volumes].each_with_index do |volume_cfg, instance_vol_idx|
          load_volume_cfg(cluster_node_id, volume_cfg)
        end
      end
    end

    def load_volume_cfg cluster_node_id, volume_cfg
      cluster_vol_id = cluster_node_id + '-' + volume_cfg[:mount_point]
      cluster_vol_params = { :cluster => self,
        :cluster_vol_id => cluster_vol_id, :cluster_node_id => cluster_node_id,
      }.merge(volume_cfg.slice(:mount_point, :size, :from_snapshot_id, :availability_zone, :device))
      @all_volumes[cluster_vol_id] = Volume.new(cluster_vol_params)
    end

  end
end

# protected
#
# # Turn the cluster_role_instance_volume_tree into a flat list of volumes,
# # an hash indexed by [role,instance_idx,instance_vol_idx]
# # interface to cluster definition from cloudera config files
# def load_from_cloudera_file
#   @all_volumes = {}
#   @all_instances  = {}
#   cluster_role_instance_volume_tree.each do |role, cluster_instance_volumes|
#     role = role
#     cluster_instance_volumes.each_with_index do |volumes, instance_idx|
#       image_id = 'ami-0b02e162' ; instance_type = 'm1.small'
#       @all_instances[ [role, instance_idx] ] = Instance.new self, role, instance_idx, image_id, instance_type
#       volumes.each_with_index do |volume, instance_vol_idx|
#         @all_volumes[[role, instance_idx, instance_vol_idx]] =
#           Volume.new(self, role, instance_idx, instance_vol_idx, volume['device'], volume['mount_point'], volume['volume_id'])
#       end
#     end
#   end
#   @all_volumes
# end
#
# # The raw cluster_role_instance_volume_tree from the cloudera EC2 cluster file
# def cluster_definition_from_cloudera_file
#   JSON.load(File.open(Settings.cluster_definition_dir + "/ec2-storage-#{name}.json"))
# end

#
# Load the cluster's logical layout from the settings file
#

module Wucluster
  class Cluster

    def to_cloudera_storage_hash
      cluster_roles = Hash.new{|hsh,role| hsh[role] = [] }
      volumes.each do |volume|
        role     = volume.instance.role
        node_idx = volume.instance.cluster_node_index.to_i
        vol_hsh = { 'device' => volume.device, 'mount_point' => volume.mount_point, 'volume_id' => volume.id }
        (cluster_roles[role][node_idx] ||= []) << vol_hsh
      end
      cluster_roles
    end

    def from_cloudera_storage_hash
      cloudera_hsh = JSON.load( File.open(File.expand_path("~/.hadoop-ec2/ec2-storage-#{name}.json")) )
      cloudera_hsh.each do |role, role_instances|
        role_instances.each_with_index do |vol_infos, node_idx|
          vol_infos.each do |vol_info|
            handle = [self.name, role, "%03d"%node_idx, vol_info['device']].join('-')
            volume = all_volumes[handle]
            raise "Couldn't find specified volume: #{handle} -- logical layout in wucluster.yaml and cloudera layout might be different" if !volume
            warn "Mismatch between layouts: #{vol_info.inspect} vs #{volume}" if (volume.device != vol_info['device']) || (volume.mount_point != vol_info['mount_point'])
            volume.id = vol_info['volume_id']
          end
        end
      end
    end

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

    #
    # Load the cluster attributes -- its availability_zone, image_id for the
    # instances, instance_type, etc.
    #
    def load_attrs
      self.availability_zone      = cluster_config[:availability_zone] || Settings.availability_zone
      self.image_id               = cluster_config[:image_id]               if cluster_config[:image_id]
      self.instance_type          = cluster_config[:instance_type]          if cluster_config[:instance_type]
      # self.deletes_on_termination = cluster_config[:deletes_on_termination] if cluster_config[:deletes_on_termination]
    end

    # loads the tree of instance descriptions and their attendant volumes'
    # descriptions
    #
    def load_instances_and_volumes
      cluster_instances = cluster_config[:instances] or return
      cluster_instances.each do |role, instances_for_role|
        role = role.to_s
        instances_for_role.each_with_index do |instance_cfg, instance_idx|
          load_instance role, instance_idx, instance_cfg
        end
      end
    end

    # takes a single layout branch describing an instance+volumes; constructs
    # the instance object and its component volume objects
    def load_instance role, instance_idx, instance_cfg
      instance_type   = instance_cfg[:instance_type] || self.instance_type
      image_id        = instance_cfg[:image_id]      || self.image_id
      cluster_node_id = [self.name, role, "%03d"%instance_idx].join('-')
      @all_instances[cluster_node_id] = Instance.new_cluster_instance(self, role, cluster_node_id, image_id, instance_type)
      if instance_cfg[:volumes]
        instance_cfg[:volumes].each_with_index do |volume_cfg, instance_vol_idx|
          load_volume(cluster_node_id, volume_cfg)
        end
      end
    end

    # constructs a volume from its layout description
    def load_volume cluster_node_id, volume_cfg
      cluster_vol_id = cluster_node_id + '-' + volume_cfg[:device]
      cluster_vol_params = {
        :cluster => self,
        :cluster_vol_id => cluster_vol_id, :cluster_node_id => cluster_node_id,
      }.merge(
        volume_cfg.slice(:mount_point, :size, :from_snapshot_id, :availability_zone, :device))
      @all_volumes[cluster_vol_id] = Volume.new(cluster_vol_params)
    end

  end
end

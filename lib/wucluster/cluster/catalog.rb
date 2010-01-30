#
# Look for cluster's manifested components among the existing crowd.
#

module Wucluster
  class Cluster

    #
    # Find all existing instances that belong to this cluster
    # and cram their metadata into the existing logical instance
    #
    def adopt_existing_instances!
      Instance.all.each do |ec2_inst|
        next if ec2_inst.deleted? || ec2_inst.deleting?
        cluster_node_id = ec2_inst.get_cluster_node_id(self.name) or next
        cluster_inst = @all_instances[cluster_node_id]            or next
        ec2_inst.update! cluster_inst.to_hash
        @all_instances[cluster_node_id] = ec2_inst
      end
    end

    #
    # Find all existing volumes that belong to this cluster
    # and cram their metadata into the existing logical volume
    #
    def adopt_existing_volumes!
      Volume.all.each do |ec2_vol|
        next if ec2_vol.deleted? || ec2_vol.deleting?
        instance = Instance.find(ec2_vol.attached_instance_id)    ; p instance ; next unless instance
        cluster_node_id = instance.get_cluster_node_id(self.name) ; next unless cluster_node_id
        cluster_vol_id  = cluster_node_id + '-' + ec2_vol.device
        volume_in_cluster = @all_volumes[cluster_vol_id]          ; next unless volume_in_cluster
        ec2_vol.update! volume_in_cluster.logical_attributes
        @all_volumes[cluster_vol_id] = ec2_vol
      end
    end

    # def catalog_existing_snapshots
    #   return unless @all_instances
    #   volume_infos = Snapshot.all.sort_by(&:created_at).map(&:volume_info).compact
    #   snapshots_for_volumes = { }
    #   volume_infos.each do |mnt_info|
    #     next unless mnt_info[:cluster_name].to_s == name.to_s
    #     snapshots_for_volumes[ [mnt_info[:role], mnt_info[:instance_idx], mnt_info[:instance_vol_idx] ] ] = mnt_info
    #   end
    #   snapshots_for_volumes.each do |mnt_id, mnt_info|
    #     volume = @all_volumes[mnt_id] or next
    #     next if volume.created? || volume.creating?
    #     volume.from_snapshot_id = mnt_info[:from_snapshot_id]
    #   end
    # end
    #

  end
end

module Wucluster
  class Cluster
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

    def adopt_existing_instances!
      Instance.all.each do |ec2_inst|
        next if ec2_inst.deleted? || ec2_inst.deleting?
        cluster_node_id = ec2_inst.get_cluster_node_id(self.name) or next
        cluster_inst = @all_instances[cluster_node_id] or next
        cluster_inst.update! ec2_inst.to_hash
      end
    end

    def adopt_existing_volumes!
      Volume.all.each do |ec2_vol|
        next if ec2_vol.deleted? || ec2_vol.deleting?
        cluster_vol_id = 'bonobo-master-000-/ebs2' # ec2_vol.get_cluster_vol_id(self.name) or next
        cluster_vol = @all_volumes[cluster_vol_id] or next
        cluster_vol.update! ec2_vol.to_hash
      end
    end


    #
    # def catalog_existing
    #   most_recent_snapshots = catalog_existing_snapshots
    #   [recent_snapshots]
    # end

  end
end

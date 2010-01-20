module Wucluster
  class Ec2Volume

    # list of all volumes
    def self.volumes
      volumes_map.values
    end
    # Hash of all ec2_volumes, :volume_id => Ec2Volume instance
    def self.volumes_map
      @volumes_map ||= self.load_volumes_map!
    end
    # Retrieve volume from volumes map, or by querying AWS directly
    def self.find volume_id
      volumes_map[volume_id.to_s]
    end

    # refreshes info from AWS, flushing any current status
    def refresh!
      response = Wucluster.ec2.describe_volumes(:volume_id => volume_id, :owner_id => Wucluster.aws_account_id)
      volume_info = response.volumeSet.item.first rescue nil
      merge_api_response! volume_info
    end

  protected

    # retrieve info for all volumes from AWS
    def self.load_volumes_map!
      Log.info "Loading volume list"
      @volumes_map = {}
      response = Wucluster.ec2.describe_volumes(:owner_id => Wucluster.aws_account_id)
      response.volumeSet.item.each do |volume_info|
        self.new_from_api_response(volume_info)
      end
      Log.info "Loaded list of #{@volumes_map.length} volumes"
      @volumes_map
    end

    # retrieve volume info from AWS directly
    #      {"attachmentSet"=>nil, "createTime"=>"2009-11-02T14:31:53.000Z", "size"=>"100",
    #       "volumeId"=>"vol-bfd826d6", "snapshotId"=>"snap-0429a56d", "status"=>"available", "availabilityZone"=>"us-east-1d"},
    def self.load_volume volume_id
      response = Wucluster.ec2.describe_volumes(:volume_id => volume_id, :owner_id => Wucluster.aws_account_id)
      volume_info = response.volumeSet.item.first rescue nil
      self.new_from_api_response(volume_info)
    end

    def self.add_volume ec2_volume
      @volumes_map[ec2_volume.id] = ec2_volume
    end

    def self.new_from_api_response volume_info
      ec2_volume = self.new()
      ec2_volume.merge_api_response!(volume_info)
      add_volume ec2_volume
      ec2_volume
    end

    API_ATTR_MAPPING = {
      'volumeId'         => :id,
      'size'             => :size,
      'snapshotId'       => :snapshot_id,
      'availabilityZone' => :availability_zone,
      'status'           => :status,
      'createTime'       => :created_at,
      'attachmentSet'    => :attachment_set,
    }

    # construct instance using hash as sent back from AWS
    def merge_api_response!(volume_info)
      volume_info.each do |api_attr, val|
        attr = API_ATTR_MAPPING[api_attr] or next
        self.send("#{attr}=", val)
      end
    end
  end
end

module Wucluster
  class Ec2Volume

    # list of all volumes
    def self.volumes
      volumes_map.values
    end
    # Hash of all ec2_volumes, :id => Ec2Volume instance
    def self.volumes_map
      @volumes_map ||= load_volumes_map!
    end
    # Force reload of
    def self.refresh!
      @volumes_map = load_volumes_map!
    end
    # Retrieve volume from volumes map, or by querying AWS directly
    def self.find id
      volumes_map[id.to_s]
    end

    # construct instance using hash as sent back from AWS
    def merge_api_response!(volume_info)
      self.id                  = volume_info['volumeId']
      self.size                = volume_info['size'].to_i if volume_info['size']
      self.from_snapshot_id    = volume_info['snapshotId']
      self.availability_zone   = volume_info['availabilityZone']
      self.status              = volume_info['status'].to_sym
      self.created_at_str      = Time.parse(volume_info['createTime']) if volume_info['createTime']
      self.attachment_set      = volume_info['attachmentSet']
    end

  protected

    #
    # virtual setter for pulling attachment info from api response
    def attachment_set= hsh
      return unless hsh
      attachment_set = hsh['item'].first
      self.attached_at             = Time.parse(attachment_set['attachTime'])
      self.attachment_device       = attachment_set['device']
      self.deletes_on_termination  = attachment_set['deleteOnTermination']
      self.attached_instance_id    = attachment_set['instanceId']
      self.attachment_status       = attachment_set['status'].to_sym
    end

    # retrieve info for all volumes from AWS
    def self.load_volumes_map!
      Log.info "Loading volume list"
      @volumes_map = {}
      response = Wucluster.ec2.describe_volumes(:owner_id => Settings.aws_account_id)
      response.volumeSet.item.each do |volume_info|
        self.new_from_api_response(volume_info)
      end
      Log.info "Loaded list of #{@volumes_map.length} volumes"
      @volumes_map
    end

    # construct a new volume from the api response
    def self.new_from_api_response volume_info
      ec2_volume = self.new()
      ec2_volume.merge_api_response!(volume_info)
      add_volume ec2_volume
      ec2_volume
    end

    # enroll volume in list of all volumes
    def self.add_volume ec2_volume
      @volumes_map[ec2_volume.id] = ec2_volume
    end

    # # retrieve volume info from AWS directly
    # #      {"attachmentSet"=>nil, "createTime"=>"2009-11-02T14:31:53.000Z", "size"=>"100",
    # #       "volumeId"=>"vol-bfd826d6", "snapshotId"=>"snap-0429a56d", "status"=>"available", "availabilityZone"=>"us-east-1d"},
    # def self.load_volume id
    #   response = Wucluster.ec2.describe_volumes(:volume_id => id, :owner_id => Settings.aws_account_id)
    #   volume_info = response.volumeSet.item.first rescue nil
    #   self.new_from_api_response(volume_info)
    # end

    # # refreshes info from AWS, flushing any current status
    # def refresh!
    #   # response = Wucluster.ec2.describe_volumes(:volume_id => id, :owner_id => Settings.aws_account_id)
    #   # volume_info = response.volumeSet.item.first rescue nil
    #   # merge_api_response! volume_info
    # end
  end
end

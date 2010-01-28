module Wucluster
  class Volume

    # Fetch current state from remote API
    def refresh!
      clear_attachment_info!
      response = Wucluster.ec2.describe_volumes(:volume_id => id, :owner_id => Settings.aws_account_id)
      update! self.class.api_hsh_to_params(response.volumeSet.item.first)
    end

    # update internal state using a full api response
    def update! *args
      clear_attachment_info!
      super(*args)
    end

    protected

    # retrieve info for all volumes from AWS
    def self.each_api_item &block
      response = Wucluster.ec2.describe_volumes(:owner_id => Settings.aws_account_id)
      response.volumeSet.item.each(&block)
    end

    # construct instance using hash as sent back from AWS
    def self.api_hsh_to_params(api_hsh)
      hsh = {
        :id                  => api_hsh['volumeId'],
        :from_snapshot_id    => api_hsh['snapshotId'],
        :availability_zone   => api_hsh['availabilityZone'], }
      hsh[:existence_status] = api_hsh['status'].gsub(/-/,"_").to_sym if api_hsh['status']
      hsh[:size]             = api_hsh['size'].to_i if api_hsh['size']
      hsh[:created_at]       = Time.parse(api_hsh['createTime']) if api_hsh['createTime']
      attachment_hsh = api_hsh['attachmentSet']['item'].first rescue nil
      hsh.merge!( attachment_hsh_to_params(attachment_hsh) )
      hsh
    end

    # convert params for the attachment segment of aws api responses
    def self.attachment_hsh_to_params attachment_hsh
      return {} unless attachment_hsh
      {
        :attached_at             => Time.parse(attachment_hsh['attachTime']),
        :device                  => attachment_hsh['device'],
        :deletes_on_termination  => attachment_hsh['deleteOnTermination'],
        :attached_instance_id    => attachment_hsh['instanceId'],
        :attachment_status       => attachment_hsh['status'].to_sym,
      }
    end

    # clear the attachment segment of the internal state
    def clear_attachment_info!
      [:attached_at, :attached_instance_id, :attachment_status].each{|attr| self.send("#{attr}=", nil)}
    end
  end
end

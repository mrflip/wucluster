module Wucluster
  class Ec2Instance

    def refresh!
      return unless self.id
      response_wrapper = Wucluster.ec2.describe_instances :instance_id => [self.id]
      response = response_wrapper.reservationSet.item.first
      merge_api_response! response
    end

  private

    def self.load_instances_map!
      resp = Wucluster.ec2.describe_instances
      @instances_map = {}
      resp.reservationSet.item.each do |response|
        self.new_from_api_response response
      end
      @instances_map
    end

    def self.add_instance ec2_instance
      @instances_map[ec2_instance.id] = ec2_instance
    end

    def self.new_from_api_response instance_info
      ec2_instance = self.new
      ec2_instance.merge_api_response!(instance_info)
      add_instance ec2_instance
      ec2_instance
    end

    API_ATTR_MAPPING = {
      "instanceId"           => :id,
      "keyName"              => :key_name,
      "instanceType"         => :instance_type,
      "ipAddress"            => :public_ip,
      "privateIpAddress"     => :private_ip,
      "launchTime"           => :launched_at,
      "placement"            => :_placement,
      "instanceState"        => :_instance_state,
      # "imageId"            => :image_id,
      # "kernelId"           => "aki-a71cf9ce", "amiLaunchIndex"=>"0", "reason"=>nil, "rootDeviceType"=>"instance-store", "blockDeviceMapping" =>nil, "ramdiskId"=>"ari-a51cf9cc", "productCodes"       =>nil,
    }

    # virtual setter
    def _placement= placement_info
      self.availability_zone = placement_info['availabilityZone']
    end
    def _instance_state= state_info
      self.status = state_info['name']
    end

    def merge_api_response! response
      instance_info = response.instancesSet.item.first
      instance_info.each do |api_attr, val|
        attr = API_ATTR_MAPPING[api_attr] or next
        self.send("#{attr}=", val)
      end
      group_info = response.groupSet.item
      self.security_groups = group_info.map{|gh| gh['groupId']}
    end

  end
end

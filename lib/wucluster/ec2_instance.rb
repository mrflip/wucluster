module Wucluster
  class Ec2Instance
    # Unique ID of a machine image.
    attr_accessor :id
    # instance status: pending, running, shutting-down, terminated, stopping, stopped
    attr_accessor :status
    # The name of the key pair.
    attr_accessor :key_name
    # Name of the security group.
    attr_accessor :security_groups
    # Placement constraints (Availability Zones) for launching the instances.
    attr_accessor :availability_zone
    # Size of the instance to launch (m1.small | m1.large | m1.xlarge | c1.medium | c1.xlarge | m2.2xlarge | m2.4xlarge)
    attr_accessor :instance_type

    attr_accessor :private_ip
    attr_accessor :public_ip
    attr_accessor :launched_at


    def initialize id = nil
      self.id = id
      self.refresh!
    end

    # Launches a specified number of instances of an AMI for which you have permissions.
    #
    # Amazon API Docs : HTML[http://docs.amazonwebservices.com/AWSEC2/2009-10-31/APIReference/index.html?ApiReference-query-RunInstances.html]
    #
    def run! image_id, options={}
      resp = Wucluster.ec2.start_instances     options.reverse_merge(:image_id => image_id,
        :key_name => key_name, :security_groups => security_groups, :availability_zone => availability_zone,
        :instance_type => instance_type)
    end

    def instantiate! *args
      run! *args
    end
    def terminate! options={}
      Wucluster.ec2.terminate_instances options.reverse_merge(:instance_id => [self.id])
    end

    # alias for #terminate!
    def delete! *args
      terminate *args
    end

    # #
    # def start! options={}
    #   Wucluster.ec2.start_instances     options.reverse_merge(:instance_id => [self.id])
    # end
    # #
    # def stop! options={}
    #   Wucluster.ec2.stop_instances      options.reverse_merge(:instance_id => [self.id], :force => false)
    # end
    # #
    # def reboot! options={}
    #   Wucluster.ec2.reboot_instances    options.reverse_merge(:instance_id => [self.id])
    # end
    # #

    def refresh!
      return unless self.id
      response_wrapper = Wucluster.ec2.describe_instances :instance_id => [self.id]
      response = response_wrapper.reservationSet.item.first
      load_from_api_response! response
    end

    def load_from_api_response! hsh
      instance_info = hsh.instancesSet.item.first
      instance_info.each do |api_attr, val|
        attr = API_ATTR_MAPPING[api_attr] or next
        self.send("#{attr}=", val)
      end
      group_info = hsh.groupSet.item
      self.security_groups = group_info.map{|gh| gh['groupId']}
    end

  private

    # Output type identifier ("RESERVATION", "INSTANCE")
    # Instance ID for each running instance
    # AMI ID of the image on which the instance is based
    # Public DNS name associated with the instance. This is only present for instances in the running state
    # Private DNS name associated with the instance. This is only present for instances in the running state
    # Instance state
    # Key name. If a key was associated with the instance at launch, its name will appear
    # AMI launch index
    # Product codes attached to the instance
    # Instance type. The type of the instance
    # Instance launch time. The time the instance launched
    # Availability Zone. The Availability Zone in which the instance is located
    # Monitoring state

    API_ATTR_MAPPING = {
      "keyName"              => :key_name,
      "instanceType"         => :instance_type,
      "ipAddress"            => :public_ip,
      "privateIpAddress"     => :private_ip,
      "launchTime"           => :launched_at,
      "placement"            => :_placement,
      "instanceState"        => :_instance_state,
      # "imageId"            => :image_id,
      # "instanceId"         => :id,
      # "kernelId"           => "aki-a71cf9ce", "amiLaunchIndex"=>"0", "reason"=>nil, "rootDeviceType"=>"instance-store", "blockDeviceMapping" =>nil, "ramdiskId"=>"ari-a51cf9cc", "productCodes"       =>nil,
    }

    # virtual setter
    def _placement= placement_info
      self.availability_zone = placement_info['availabilityZone']
    end
    def _instance_state= state_info
      self.status = state_info['name']
    end

    def self.load_instances
      resp = Wucluster.ec2.describe_instances
      instances = []
      resp.reservationSet.item.each do |response|
        id = response.instancesSet.item.first['instanceId']
        instance = self.new id
        instance.load_from_api_response! response
        instances << instance
      end
      instances
    end
  end
end

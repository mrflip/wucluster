require 'wucluster/ec2_instance/api'
module Wucluster
  class Ec2Instance
    include Ec2Proxy

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
    # IP address of the internal interface
    attr_accessor :private_ip
    # IP address of the external interface
    attr_accessor :public_ip
    # Instance launch time. The time the instance launched
    attr_accessor :created_at
    #
    attr_accessor :image_id

    #
    def initialize hsh
      update! hsh
    end
    # retrieve info for all volumes from AWS
    def self.each_api_item &block
      response = Wucluster.ec2.describe_instances
      p [response, response.reservationSet.item]
      response.reservationSet.item.each(&block)
    end

    def to_hash
      %w[id status key_name security_groups availability_zone instance_type public_ip private_ip created_at image_id
        ].inject({}){|hsh, attr| hsh[attr.to_sym] = self.send(attr); hsh}
    end

    # construct instance using hash as sent back from AWS
    def self.api_hsh_to_params(api_hsh)
      instance_info = api_hsh.instancesSet.item.first
      group_info    = api_hsh.groupSet.item
      hsh = {
        :id              => instance_info["instanceId"],
        :key_name        => instance_info["keyName"],
        :instance_type   => instance_info["instanceType"],
        :public_ip       => instance_info["ipAddress"],
        :private_ip      => instance_info["privateIpAddress"],
        :security_groups => group_info.map{|gh| gh['groupId']},
        :image_id        => instance_info["imageId"],
        # "kernelId" => "aki-a71cf9ce", "amiLaunchIndex"=>"0", "reason"=>nil, "rootDeviceType"=>"instance-store", "blockDeviceMapping" =>nil, "ramdiskId"=>"ari-a51cf9cc", "productCodes"       =>nil,
      }
      hsh[:created_at]        = Time.parse(instance_info["launchTime"])        rescue nil
      hsh[:availability_zone] = instance_info["placement"]['availabilityZone'] rescue nil
      hsh[:status]            = instance_info["instanceState"]['name']         rescue nil
      hsh
    end

    # Launches a specified number of instances of an AMI for which you have permissions.
    #
    # Amazon API Docs : HTML[http://docs.amazonwebservices.com/AWSEC2/2009-10-31/APIReference/index.html?ApiReference-query-RunInstances.html]
    #
    # image_id [String] Unique ID of a machine image.
    # @option options [Integer] :min_count (1) Minimum number of instances to launch. If the value is more than Amazon EC2 can launch, no instances are launched at all.
    # @option options [Integer] :max_count (1) Maximum number of instances to launch. If the value is more than Amazon EC2 can launch, the largest possible number above minCount will be launched instead.
    # @option options [optional, String] :additional_info (nil) Specifies additional information to make available to the instance(s).
    # @option options [optional, String] :user_data (nil) MIME, Base64-encoded user data (if :base64_encoded is false) or user_data plaintext (if :base64_encoded is true).
    # @option options [optional, Boolean] :base64_encoded (false) Whether or not to encode the user_data
    # @option options [optional, String] :kernel_id (nil) The ID of the kernel with which to launch the instance.
    # @option options [optional, String] :ramdisk_id (nil) The ID of the RAM disk with which to launch the instance. Some kernels require additional drivers at launch. Check the kernel requirements for information on whether you need to specify a RAM disk. To find kernel requirements, go to the Resource Center and search for the kernel ID.
    # @option options [optional, Array]   :block_device_mapping ([]) An array of Hashes representing the elements of the block device mapping.  e.g. [{:device_name => '/dev/sdh', :virtual_name => '', :ebs_snapshot_id => '', :ebs_volume_size => '', :ebs_delete_on_termination => ''},{},...]
    # @option options [optional, Boolean] :monitoring_enabled (false) Enables monitoring for the instance.
    # @option options [optional, String] :subnet_id (nil) Specifies the Amazon VPC subnet ID within which to launch the instance(s) for Amazon Virtual Private Cloud.
    # @option options [optional, Boolean] :disable_api_termination (true) Specifies whether the instance can be terminated using the APIs. You must modify this attribute before you can terminate any "locked" instances from the APIs.
    # @option options [optional, String] :instance_initiated_shutdown_behavior ('stop') Specifies whether the instance's Amazon EBS volumes are stopped or terminated when the instance is shut down. Valid values : 'stop', 'terminate'
    #
    def run! options={}
      response = Wucluster.ec2.run_instances options.merge(:image_id => image_id,
        :key_name => key_name, :security_groups => security_groups, :availability_zone => availability_zone,
        :instance_type => instance_type)
      p response
      update! self.class.api_hsh_to_params(response)
      undirty!
    end

    # The TerminateInstances operation shuts down one or more instances.
    def terminate! options={}
      response = Wucluster.ec2.terminate_instances options.merge(:instance_id => [self.id])
      new_state = response.instancesSet.item.first.currentState.name rescue nil
      Log.warn "Request returned funky status: #{new_state}" unless (['shutting-down', 'terminated'].include? new_state)
      dirty!
      response
    end

  end
end


    # def merge_api_response! response
    #   instance_info = response.instancesSet.item.first
    #   instance_info.each do |api_attr, val|
    #     attr = API_ATTR_MAPPING[api_attr] or next
    #     self.send("#{attr}=", val)
    #   end
    #   group_info = response.groupSet.item
    #   self.security_groups = group_info.map{|gh| gh['groupId']}
    # end

    # Output type identifier ("RESERVATION", "INSTANCE")
    # AMI ID of the image on which the instance is based
    # AMI launch index
    # Product codes attached to the instance
    # Monitoring state

    # #
    # def start! options={}
    #   resp = Wucluster.ec2.start_instances     options.merge(:instance_id => [self.id])
    # end
    # #
    # def stop! options={}
    #   resp = Wucluster.ec2.stop_instances      options.merge(:instance_id => [self.id])
    # end
    # #
    # def reboot! options={}
    #   resp = Wucluster.ec2.reboot_instances    options.merge(:instance_id => [self.id])
    # end
    # #

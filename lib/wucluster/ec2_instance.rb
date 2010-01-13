module Wucluster
  class Ec2Instance



    # Launches a specified number of instances of an AMI for which you have permissions.
    #
    # Amazon API Docs : HTML[http://docs.amazonwebservices.com/AWSEC2/2009-10-31/APIReference/index.html?ApiReference-query-RunInstances.html]
    #
    # @option options [String] :image_id ("") Unique ID of a machine image.
    # @option options [Integer] :min_count (1) Minimum number of instances to launch. If the value is more than Amazon EC2 can launch, no instances are launched at all.
    # @option options [Integer] :max_count (1) Maximum number of instances to launch. If the value is more than Amazon EC2 can launch, the largest possible number above minCount will be launched instead.
    # @option options [optional, String] :key_name (nil) The name of the key pair.
    # @option options [optional, String] :security_group (nil) Name of the security group.
    # @option options [optional, String] :additional_info (nil) Specifies additional information to make available to the instance(s).
    # @option options [optional, String] :user_data (nil) MIME, Base64-encoded user data.
    # @option options [optional, String] :instance_type (nil) Specifies the instance type.
    # @option options [optional, String] :availability_zone (nil) Specifies the placement constraints (Availability Zones) for launching the instances.
    # @option options [optional, String] :kernel_id (nil) The ID of the kernel with which to launch the instance.
    # @option options [optional, String] :ramdisk_id (nil) The ID of the RAM disk with which to launch the instance. Some kernels require additional drivers at launch. Check the kernel requirements for information on whether you need to specify a RAM disk. To find kernel requirements, go to the Resource Center and search for the kernel ID.
    # @option options [optional, Array] :block_device_mapping ([]) An array of Hashes representing the elements of the block device mapping.  e.g. [{:device_name => '/dev/sdh', :virtual_name => '', :ebs_snapshot_id => '', :ebs_volume_size => '', :ebs_delete_on_termination => ''},{},...]
    # @option options [optional, Boolean] :monitoring_enabled (false) Enables monitoring for the instance.
    # @option options [optional, String] :subnet_id (nil) Specifies the Amazon VPC subnet ID within which to launch the instance(s) for Amazon Virtual Private Cloud.
    # @option options [optional, Boolean] :disable_api_termination (true) Specifies whether the instance can be terminated using the APIs. You must modify this attribute before you can terminate any "locked" instances from the APIs.
    # @option options [optional, String] :instance_initiated_shutdown_behavior ('stop') Specifies whether the instance's Amazon EBS volumes are stopped or terminated when the instance is shut down. Valid values : 'stop', 'terminate'
    # @option options [optional, Boolean] :base64_encoded (false)
    def instantiate!
    end
    def run! *args
      instantiate! *args
    end
    #
    def start! options={}
      Wucluster.ec2.start_instances options.reverse_merge(:instance_id => [self.id])
    end
    #
    def stop! options={}
      Wucluster.ec2.start_instances options.reverse_merge(
          :instance_id => [self.id], :force => false)
    end
    #
    def reboot! options={}
      Wucluster.ec2.reboot_instances options.reverse_merge(:instance_id => [self.id])
    end
    #
    def delete! options={}
      Wucluster.ec2.terminate_instances options.reverse_merge(:instance_id => [self.id])
    end
    def terminate! *args
      delete! *args
    end

    def refresh!
      load_instance
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

    def load_instance
      Wucluster.ec2.describe_instances :instance_id => [self.id]
    end
    def load_instances
      Wucluster.ec2.describe_instances :instance_id => [self.id]
    end
  end
end

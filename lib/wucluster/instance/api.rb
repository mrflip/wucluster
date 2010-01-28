module Wucluster
  class Instance

    def pending?()       status == :pending        end
    def running?()       status == :running        end
    def terminated?()    status == :terminated     end
    def deleted?()        terminated?  end
    def shutting_down?() status == :shutting_down  end
    def terminating?()   shutting_down?  end
    def deleting?()      shutting_down?  end


    def get_cluster_node_id cluster_name
      # return unless security_groups.include?(cluster_name.to_s)
      security_groups.find_all{|sg| sg =~ /^#{cluster_name}-/}.sort.last
    end
    # ===========================================================================
    #
    # Actions
    #

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
      return :wait if pending? || running?
      Log.info "Running #{self}"
      response = Wucluster.ec2.run_instances options.merge(:image_id => image_id,
        :key_name => key_name, :security_group => security_groups, :availability_zone => availability_zone,
        :instance_type => instance_type)
      update! self.class.api_hsh_to_params(response)
      self.class.register self
      undirty!
    end

    # make a new volume proxy and create it on the remote end
    def self.create! *args
      inst = new *args
      inst.run!
      inst
    end

    # The TerminateInstances operation shuts down one or more instances.
    def terminate! options={}
      return :wait if terminating? || terminated?
      Log.info "Terminating #{self}"
      response = Wucluster.ec2.terminate_instances options.merge(:instance_id => [self.id])
      new_state = response.instancesSet.item.first.currentState.name rescue nil
      Log.warn "Request returned funky status: #{new_state}" unless (['shutting-down', 'terminated'].include? new_state)
      self.status = new_state.gsub(/-/,'_').to_sym
      dirty!
      response
    end

    # ===========================================================================
    #
    # API
    #

    # retrieve info for all volumes from AWS
    def self.each_api_item &block
      response = Wucluster.ec2.describe_instances
      response.reservationSet.item.each(&block)
    end

    def refresh!
      response = Wucluster.ec2.describe_instances(:instance_id => id)
      update! self.class.api_hsh_to_params(response.reservationSet.item.first)
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
      hsh[:created_at]        = Time.parse(instance_info["launchTime"])                     rescue nil
      hsh[:availability_zone] = instance_info["placement"]['availabilityZone']              rescue nil
      hsh[:status]            = instance_info["instanceState"]['name'].gsub(/-/,'_').to_sym rescue nil
      hsh
    end

    #
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
  end
end

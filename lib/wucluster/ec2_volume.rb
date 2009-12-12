module Wucluster
  Ec2Volume = Struct.new(
    :id,
    :size,
    :from_snapshot_id,
    :zone,
    :status,
    :created_at,
    :attached_instance
    )
  Ec2Volume.class_eval do

    #
    # Volume operations
    #

    def create_snapshot options={}
      Wucluster.ec2.create_snapshot options.merge(:volume_id => self.id,
        :description => handle
        )
    end

    # removes volume from its instance
    def detach options={}
      Wucluster.ec2.detach_volume options.merge(:volume_id => self.id)
    end

    # def attach_volume(options={}) end
    # def self.create_volume(options={}) end
    # def delete(options={}) end

    #
    # Attachment info
    #

    # attached_instance={"item"=>[{"device"=>"/dev/sdf",
    # "volumeId"=>"vol-e59e638c", "deleteOnTermination"=>"false",
    # "instanceId"=>"i-8f0354e6", "attachTime"=>"2009-10-03T20:48:49.000Z",
    # "status"=>"attached"}]}

    # def device()            end
    # def instance()          end
    # def instance_id()       end
    # def attached_at()       end
    # def attachment_status() end

    #
    # Facade for EC2 API
    #

    # Hash of all ec2_volumes
    def self.all
      @all ||= self.load_volumes_list!
    end

    def self.volumes
      all.values
    end

    # Retrieve volume from list of all volumes, or by querying AWS directly
    def self.find volume_id
      all[volume_id.to_s] || self.from_id(volume_id)
    end

    # refreshes info from AWS, flushing any current state
    def refresh!
      merge! self.class.from_id(self.id)
    end

  protected

    #
    # Load all volumes from AWS
    def self.load_volumes_list!
      @all = {}
      Wucluster.ec2.describe_volumes.volumeSet.item.each do |volume_hsh|
        @all[volume_hsh['volumeId']] = self.from_ec2(volume_hsh)
      end
      Log.info "Loaded list of #{@all.length} volumes"
      @all
    end

    # Create volume using info retrieved from AWS directly
    #      {"attachmentSet"=>nil, "createTime"=>"2009-11-02T14:31:53.000Z", "size"=>"100",
    #       "volumeId"=>"vol-bfd826d6", "snapshotId"=>"snap-0429a56d", "status"=>"available", "availabilityZone"=>"us-east-1d"},
    def self.from_ec2 volume_id
      volume_hsh = Wucluster.ec2.describe_volumes(:volume_id => volume_id).volumeSet.item.first rescue nil
      self.from_ec2_hsh volume_hsh
    end

    # Use the hash sent back from AWS to construct an Ec2Volume instance
    def self.from_ec2_hsh(volume_hsh)
      return nil if volume_hsh.blank?
      self.new(* volume_hsh.values_of('volumeId', 'size', 'snapshotId', 'availabilityZone', 'status', 'createTime', 'attachmentSet'))
    end

  end
end

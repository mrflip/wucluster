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
    # States
    #

    def detached?
      (  attached_instance.nil?) && (%w[available deleting].include? status)
    end
    def attached?
      (! attached_instance.nil?) && (status == "available")
    end
    def transitional?
      %w[deleting ].include? status
    end

    #
    # Operations
    #

    # attaches volume to its instance
    def attach options={}
      return if attached?
      Log.info "Detaching #{id}: #{[attached_instance, status].inspect}"
      Wucluster.ec2.detach_volume options.merge(:volume_id => self.id)
    end

    # removes volume from its instance
    def detach options={}
      return if detached?
      Log.info "Detaching #{id}: #{[attached_instance, status].inspect}"
      Wucluster.ec2.detach_volume options.merge(:volume_id => self.id)
    end

    #
    # Association
    #

    def mount
      Mount.find(id)
    end

    def mount_handle
      mount.handle
    end

    #
    # Facade for EC2 API
    #

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
      volumes_map[volume_id.to_s] # || self.load_volume(volume_id)
    end

    # refreshes info from AWS, flushing any current state
    def refresh!
      merge! self.class.load_volume(self.id)
    end

  protected

    # retrieve info for all volumes from AWS
    def self.load_volumes_map!
      Log.info "Loading volume list"
      @volumes_map = {}
      Wucluster.ec2.describe_volumes(:owner_id => Wucluster.aws_account_id).volumeSet.item.each do |volume_hsh|
        @volumes_map[volume_hsh['volumeId']] = self.from_hsh(volume_hsh)
      end
      Log.info "Loaded list of #{@volumes_map.length} volumes"
      @volumes_map
    end

    # retrieve volume info from AWS directly
    #      {"attachmentSet"=>nil, "createTime"=>"2009-11-02T14:31:53.000Z", "size"=>"100",
    #       "volumeId"=>"vol-bfd826d6", "snapshotId"=>"snap-0429a56d", "status"=>"available", "availabilityZone"=>"us-east-1d"},
    def self.load_volume volume_id
      volume_hsh = Wucluster.ec2.describe_volumes(:volume_id => volume_id, :owner_id => Wucluster.aws_account_id).volumeSet.item.first rescue nil
      self.from_hsh volume_hsh
    end

    # construct instance using hash as sent back from AWS
    def self.from_hsh(volume_hsh)
      return nil if volume_hsh.blank?
      self.new(* volume_hsh.values_of('volumeId', 'size', 'snapshotId', 'availabilityZone', 'status', 'createTime', 'attachmentSet'))
    end

  end
end

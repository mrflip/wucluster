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

    # def self.create_volume(options={}) end

    # def attach_volume(options={}) end

    # Create a snapshot of the volume, including metadata in
    # the description to make it recoverable
    def create_snapshot options={}
      Log.info "Creating snapshot for #{id} as #{mount_handle}"
      Wucluster.ec2.create_snapshot options.merge(:volume_id => self.id, :description => mount_handle   )
    end

    # removes volume from its instance
    def detach! options={}
      return if detached?
      Log.info "Detaching #{id}: #{[attached_instance, status].inspect}"
      Wucluster.ec2.detach_volume options.merge(:volume_id => self.id)
    end

    def detached?()
      attached_instance.nil? && (%w[available deleting].include? status)
    end
    def attached?() not detached? end

    def newest_snapshot
      snapshots.sort_by(&:created_at).find_all(&:completed?).last
    end
    def has_recent_snapshot?
      newest_snapshot && newest_snapshot.recent?
    end

    def delete_if_has_recent_snapshot!()
      if    status != "available"
        Log.info "Not removing #{id}: volume is #{status}"
        return
      elsif ! has_recent_snapshot?
        Log.info "Not removing #{id}: #{newest_snapshot ? "{newest_snapshot.description} is too old" : "no snapshot exists"}"
        return
      else
        Log.info "Deleting #{id}: have recent snapshot #{newest_snapshot.description}"
        Wucluster.ec2.delete_volume :volume_id => self.id
      end
    end

    #
    # Associated Snapshots
    #
    def snapshots
      Wucluster::Ec2Snapshot.for_volume id
    end

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

    def mount_handle
      ClusterMount.find(id).handle
    end

    # Hash of all ec2_volumes, :volume_id => Ec2Volume instance
    def self.all
      @all ||= self.load_volumes_list!
    end
    # list of all volumes
    def self.volumes
      all.values
    end

    # Retrieve volume from list of all volumes, or by querying AWS directly
    def self.find volume_id
      all[volume_id.to_s] # || self.from_ec2(volume_id)
    end

    # refreshes info from AWS, flushing any current state
    def refresh!
      merge! self.class.from_ec2(self.id)

    end

  protected

    # retrieve info for all volumes from AWS
    def self.load_volumes_list!
      Log.info "Loading volume list"
      @all = {}
      Wucluster.ec2.describe_volumes(:owner_id => Wucluster.aws_account_id).volumeSet.item.each do |volume_hsh|
        @all[volume_hsh['volumeId']] = self.from_hsh(volume_hsh)
      end
      Log.info "Loaded list of #{@all.length} volumes"
      @all
    end

    # retrieve volume info from AWS directly
    #      {"attachmentSet"=>nil, "createTime"=>"2009-11-02T14:31:53.000Z", "size"=>"100",
    #       "volumeId"=>"vol-bfd826d6", "snapshotId"=>"snap-0429a56d", "status"=>"available", "availabilityZone"=>"us-east-1d"},
    def self.from_ec2 volume_id
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

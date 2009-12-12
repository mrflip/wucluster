module Wucluster

  #
  # Facade for an EBS Snapshot
  #
  Ec2Snapshot = Struct.new(
    :id,
    :volume_id,
    :status,
    :created_at,
    :progress,
    :owner_id,
    :size,
    :volume_handle
    )

  Ec2Snapshot.class_eval do
    cattr_accessor :list
    attr_accessor :volume, :mount_point

    #
    # Associations
    #

    # The volume associated with this snapshot
    def volume
      @volume ||= Ec2Volume.find volume_id
    end

    def mount_point
      @mount_point ||= ClusterMount.from_handle volume_handle
    end

    #
    # Facade for EC2 API
    #

    # Hash of all ec2_snapshots
    def self.all
      @all ||= self.load_snapshots_list!
    end

    def self.snapshots
      all.values
    end

    # Retrieve snapshot from list of all snapshots, or by querying AWS directly
    def self.find snapshot_id
      all[snapshot_id.to_s] || self.from_ec2(snapshot_id)
    end

    # find all snapshots for the given volume
    def self.for_volume volume_id
      snapshots.find_all{|snapshot| snapshot.volume_id == volume_id }.sort_by(&:created_at)
    end

    # refreshes info from AWS, flushing any current state
    def refresh!
      merge! self.class.from_ec2(self.id)
    end

  protected

    # retrieve all snapshots from AWS
    def self.load_snapshots_list!
      @all = {}
      Wucluster.ec2.describe_snapshots(:owner_id => Wucluster.aws_account_id).snapshotSet.item.each do |snapshot_hsh|
        @all[snapshot_hsh['snapshotId']] = self.from_ec2_hsh(snapshot_hsh)
      end
      Log.info "Loaded list of #{@all.length} snapshots"
      @all
    end

    # retrieve single snapshot from aws
    def self.from_ec2 snapshot_id
      snapshot_hsh = Wucluster.ec2.describe_snapshots(:snapshot_id => snapshot_id, :owner_id => Wucluster.aws_account_id).snapshotSet.item.first rescue nil
      self.from_ec2_hsh snapshot_hsh
    end

    # Use the hash sent back from AWS to construct an Ec2Snapshot instance
    #      {"snapshotId"=>"snap-e2f5948b", "volumeId"=>"vol-5f6a8536", "status"=>"completed",
    #      "startTime"=>"2009-12-10T19:45:11.000Z", "progress"=>"100%",
    #      "ownerId"=>"145626931636", "volumeSize"=>"20", "description"=>"12/10/09 backup"}
    def self.from_ec2_hsh(snapshot_hsh)
      return nil if snapshot_hsh.blank?
      self.new(* snapshot_hsh.values_of('snapshotId', 'volumeId',
          'status', 'startTime', 'progress', 'ownerId', 'volumeSize', 'description'))
    end

  end
end

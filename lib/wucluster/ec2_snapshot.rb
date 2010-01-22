module Wucluster
  #
  # Facade for an EBS Snapshot
  #
  class Ec2Snapshot
    include Ec2Proxy
    # Time window for figuring if a snapshot is recent
    RECENT_SNAPSHOT_AGE = 2*60*60

    # Snapshot AWS id
    attr_accessor :id
    # AWS Volume ID
    attr_accessor :volume_id
    # [Symbol] Status: pending, completed, or error
    attr_accessor :status
    # [Time] Time snapshot was created
    attr_accessor :created_at
    # The progress of the snapshot, in percentage
    attr_accessor :progress
    # The AWS account ID of the Amazon EBS snapshot owner.
    attr_accessor :owner_id
    # [Integer] Size of the volume in GiB
    attr_accessor :size
    # Description of the owning volume
    attr_accessor :volume_handle

    #
    def initialize hsh
      update! hsh
    end

    # ===========================================================================
    #
    # Associations
    #

    # The volume associated with this snapshot
    def volume
      @volume ||= Ec2Volume.find volume_id
    end

    # ===========================================================================
    #
    # Operations
    #

    # Create
    #
    def self.create! volume_id, description
      Log.info "Creating #{description}."
      response = Wucluster.ec2.create_snapshot(:volume_id => volume_id, :description => description)
      self.update! self.class.api_hsh_to_params(response)
      dirty!
    end

    # Delete the snapshot on the AWS side
    def delete!
      Log.info "Deleting #{volume_handle}. O, I die, Horatio."
      # Wucluster.ec2.delete_snapshot(:snapshot_id => id)
    end

    # ===========================================================================
    #
    # State
    #

    # Age of the snapshot in seconds
    def age
      created_at_time = Time.parse(self.created_at)
      return Time.now.utc - created_at_time
    end

    # Is the snapshot recent enough to not warrant re-snapshotting?
    def recent?
      age < RECENT_SNAPSHOT_AGE
    end

    # Has the snapshot process completed?
    def completed?
      (status == :completed) && (progress == "100%")
    end


    # Hash of all ec2_snapshots by their ID
    def self.snapshots_map
      @snapshots_map or self.load_snapshots!
    end

    # List of all snapshots
    def self.snapshots
      snapshots_map.values
    end

    # Retrieve snapshot from list of all snapshots, or by querying AWS directly
    def self.find snapshot_id
      snapshots_map[snapshot_id]
    end

  protected

    def self.each_api_item &block
      response = Wucluster.ec2.describe_snapshots
      response.snapshotSet.item.each(&block)
    end

    # Use the hash sent back from AWS to construct an Ec2Snapshot instance
    #      {"snapshotId"=>"snap-e2f5948b", "volumeId"=>"vol-5f6a8536", "status"=>"completed",
    #      "startTime"=>"2009-12-10T19:45:11.000Z", "progress"=>"100%",
    #      "ownerId"=>"145626931636", "volumeSize"=>"20", "description"=>"12/10/09 backup"}
    def self.api_hsh_to_params api_hsh
      hsh = {
        :id            => api_hsh['snapshotId'],
        :volume_id     => api_hsh['volumeId'],
        :status        => api_hsh[ 'status'],
        :progress      => api_hsh['progress'],
        :owner_id      => api_hsh['ownerId'],
        :size          => api_hsh['volumeSize'].to_i,
        :volume_handle => api_hsh['description'],
      }
      hsh[:created_at] = api_hsh[ 'startTime']
      hsh
    end

  end
end

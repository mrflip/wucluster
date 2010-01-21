module Wucluster

  #
  # Facade for an EBS Snapshot
  #
  class Ec2Snapshot
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
    # [Integer] Size of the volume in GiB
    attr_accessor :size
    # Description of the owning volume
    attr_accessor :volume_handle

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

    #
    # Operations
    #

    # Create
    def self.create!
    end

    # Delete the snapshot on the AWS side
    def delete!
      Log.info "Deleting #{description}. O, I die, Horatio."
      # Wucluster.ec2.delete_snapshot(:snapshot_id => id)
    end

    #
    # Associations
    #

    # The volume associated with this snapshot
    def volume
      @volume ||= Ec2Volume.find volume_id
    end

    def mount_point
      @mount_point ||= Mount.from_handle volume_handle
    end

  end
end

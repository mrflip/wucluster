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
    # The AWS account ID of the Amazon EBS snapshot owner.
    attr_accessor :owner_id
    # [Integer] Size of the volume in GiB
    attr_accessor :size
    # Description of the owning volume
    attr_accessor :volume_handle

    # Create a new Ec2Snapshot
    #
    # @param id              The ID of the snapshot.
    # @param volume_id       The ID of the volume.
    # @param status          Snapshot state (e.g., pending, completed, or error)
    # @param created_at      Time stamp when the snapshot was initiated.
    # @param progress        The progress of the snapshot, in percentage.
    # @param owner_id        The AWS account ID of the Amazon EBS snapshot owner.
    # @param size            [Integer] The size of the volume, in GiB.
    # @param volume_handle   [String] Description of the snapshot.
    def initialize id, volume_id, status, created_at, progress, owner_id, size, volume_handle
      self.id            = id
      self.volume_id     = volume_id
      self.status        = status.to_sym
      self.created_at    = Time.parse(created_at)
      self.progress      = progress
      self.owner_id      = owner_id
      self.size          = size.to_i
      self.volume_handle = volume_handle
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
      snapshot_hsh = response.snapshotSet.item.first rescue nil
      from_ec2_hsh(snapshot_hsh)
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

  end
end

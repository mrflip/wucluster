module Wucluster
  #
  # Facade for an EBS Snapshot
  #
  class Snapshot
    include Ec2Proxy
    ::Settings.define :recent_snapshot_age, :default => (12*60*60), :description => "Time window for figuring if a snapshot is recent"

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

    # ===========================================================================
    #
    # Associations
    #

    # Logical volume info for this snapshot
    def volume_info
      return {} if volume_handle.blank?
      fields  = volume_handle.split(/\+/)
      if fields[3] =~ /^\d+$/ then fields.slice!(3) end
      cluster_name, role, node_idx, device, mount_point, volume_id = fields
      return {} if role.blank?
      node_idx = node_idx.to_i
      size = self.size.to_i
      {
        :cluster_name     => cluster_name.to_sym,
        :cluster_node_id  => "#{cluster_name}-#{role}-#{"%03d"%node_idx}",
        :cluster_vol_id   => "#{cluster_name}-#{role}-#{"%03d"%node_idx}-#{device}",
        :device           => device,
        :mount_point      => mount_point,
        :id               => volume_id,
        :size             => size,
        :from_snapshot_id => id,
      }
    end
    def cluster_name
      volume_info[:cluster_name] unless volume_info.blank?
    end

    # The volume associated with this snapshot
    def volume
      @volume ||= Volume.find volume_id
    end

    # All snapshots in descending (latest to earliest) date order
    def self.all_by_date
      all.sort_by(&:created_at).reverse
    end

    # Look up snapshot for provided volume
    def self.for_volume_id volume_id
      return [] unless volume_id
      all_by_date.find_all{|snap| snap.volume_id == volume_id }
    end

    # Find all snapshots for given cluster (as reverse engineered from its description)
    def self.for_cluster cluster
      all_by_date.find_all{|snap| snap.cluster_name == cluster.name }
    end

    # ===========================================================================
    #
    # Operations
    #

    # Create snapshot for given volume with description provided
    def self.create! volume, description
      Log.info "Creating snapshot #{description}."
      snap = self.new(:volume_id => volume.id)
      response = Wucluster.ec2.create_snapshot(:volume_id => volume.id, :description => description)
      snap.update! api_hsh_to_params(response)
      snap.dirty!
      register snap
      snap
    end

    # Has the snapshot process completed?
    def completed?
      (status.to_s == 'completed') && (progress == "100%")
    end
    def created?() completed? end

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
      refresh!
      age < Settings.recent_snapshot_age
    end

    # Fetch current state from remote API
    def refresh!
      begin response = Wucluster.ec2.describe_snapshots(:snapshot_id => id)
      rescue AWS::Error => e
        if e.to_s =~ /snapshot .* does not exist/
          self.status = :deleted
          self.volume_id = self.progress = self.size = self.owner_id = nil
          return nil
        else raise e end
      end
      update! self.class.api_hsh_to_params(response.snapshotSet.item.first)
    end

    def to_s
      %Q{#<#{self.class} #{id} #{volume_id} #{size} #{volume_handle} #{volume_info[:cluster]} #{status} #{progress}>}
    end
    def to_str
      to_s
    end

  protected

    def self.each_api_item &block
      response = Wucluster.ec2.describe_snapshots
      response.snapshotSet.item.each(&block)
    end

    # Use the hash sent back from AWS to construct an Snapshot instance
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

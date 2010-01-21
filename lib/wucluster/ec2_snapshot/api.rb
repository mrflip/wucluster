module Wucluster
  class Ec2Snapshot

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

    # retrieve all snapshots from AWS
    def self.load_snapshots!
      Log.info "Loading snapshots list"
      @snapshots_map = {}
      response = Wucluster.ec2.describe_snapshots(:owner => Settings.aws_account_id.to_s)
      p response
      response.snapshotSet.item.each do |snapshot_hsh|
        p snapshot_hsh
        add_snapshot self.from_ec2_hsh(snapshot_hsh)
      end
      Log.info "Loaded list of #{@snapshots_map.length} snapshots"
      @snapshots_map
    end

    # Adds snapshot to the snapshots table
    def self.add_snapshot snapshot
      @snapshots_map ||= {}
      @snapshots_map[snapshot.id] = snapshot
    end

    # Use the hash sent back from AWS to construct an Ec2Snapshot instance
    #      {"snapshotId"=>"snap-e2f5948b", "volumeId"=>"vol-5f6a8536", "status"=>"completed",
    #      "startTime"=>"2009-12-10T19:45:11.000Z", "progress"=>"100%",
    #      "ownerId"=>"145626931636", "volumeSize"=>"20", "description"=>"12/10/09 backup"}
    def self.from_ec2_hsh(snapshot_hsh)
      return nil if snapshot_hsh.blank?
      p snapshot_hsh['ownerId']
      self.new(* snapshot_hsh.values_at('snapshotId', 'volumeId',
          'status', 'startTime', 'progress', 'ownerId', 'volumeSize', 'description'))
    end

  end
end

    # # find all snapshots for the given volume
    # def self.for_volume volume_id
    #   snapshots.find_all{|snapshot| snapshot.volume_id == volume_id }.sort_by(&:created_at)
    # end
    #
    # # refreshes info from AWS, flushing any current state
    # def refresh!
    #   merge! self.class.from_ec2(self.id)
    # end

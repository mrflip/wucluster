module Wucluster
  class Ec2Snapshot

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

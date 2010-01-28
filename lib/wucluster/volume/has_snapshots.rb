module Wucluster
  class Volume
    #
    # Snapshots
    #

    # Snapshot this volume was created from.
    def from_snapshot
      Wucluster::Snapshot.find(snapshot_id)
    end

    # List all snapshots for
    def snapshots
      Wucluster::Snapshot.for_volume(self)
    end

    # List the newest snapshot (regardless of its current
    def newest_snapshot
      snapshots.sort_by(&:created_at).last
    end

    #
    def recently_snapshotted?
      newest_snapshot && newest_snapshot.recent? && newest_snapshot.completed?
    end

    def snapshotting?
      newest_snapshot && (not newest_snapshot.completed?)
    end

  end
end

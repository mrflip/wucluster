module Wucluster

  Ec2Snapshot = Struct.new(
    :id,
    :volume_id,
    :status,
    :snapshot_at,
    :progress,
    :user_id,
    :size,
    :volume_handle
    )

  Ec2Snapshot.class_eval do
    cattr_accessor :list
    attr_accessor :volume, :mount_point
    # has_one :volume

    # The volume associated with this snapshot
    def volume
      @volume ||= Ec2Volume.find volume_id
    end

    def mount_point
      @mount_point ||= ClusterMount.from_handle volume_handle
    end

    def self.load_list!
      raw_snapshots = `ec2-describe-snapshots`
      raw_snapshots.map do |line| line.chomp!
        snapshot = self.new *line.split("\t", keys.length)
        p snapshot
      end
    end
  end
end

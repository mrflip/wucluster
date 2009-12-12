Ec2Volumes = Struct.new()
Ec2Volumes.class_eval do



  def self.volumes_list
    @volumes_list ||= load_volumes_list!
  end

  def load_volumes_list!
    @volumes_list = {}
    `ec2-describe-volumes`.split("\n")
  end
end

Ec2Snapshot = Struct.new(
  :type,
  :snap_id,
  :volume_id,
  :state,
  :snapshot_at,
  :progress,
  :user_id,
  :size,
  :volume_handle
  )
Ec2Snapshot.class_eval do
  cattr_accessor :list

  def volume
    @volume ||= Ec2Volume.from_handle volume_handle
  end

  def self.load_list!
    raw_snapshots = `ec2-describe-snapshots`
    raw_snapshots.map do |line| line.chomp!
      snapshot = self.new *line.split("\t", keys.length)
      p snapshot
    end
  end
end

module Wucluster
  ClusterMount = Struct.new(
    :cluster,
    :role,
    :node_idx,
    :node_vol_idx,
    :device,
    :mount_point,
    :volume_id
    )
  ClusterMount.class_eval do
    cattr_accessor :all
    self.all = {}
    def initialize *args
      super *args
      self.coerce_to_int!(:node_idx,   true)
      self.coerce_to_int!(:node_vol_idx, true)
      self.class.all[volume_id] = self
    end

    def ready?
      (   volume_active?) && (   volume_attached?)
    end
    def separated?
      (   volume_active?) && ( ! volume_attached?)
    end
    def available?
      separated?
    end
    def away?
      ( ! volume_active?) && (   snapshot_exists?)
    end
    def raw?
      ( ! volume_active?) && ( ! snapshot_exists?)
    end
    #
    # Imperatives
    #
    def make_ready
      make_created
      volume.attach!
    end
    def make_away
      make_separated
      make_recently_snapshotted
      make_away
    end

    def make_attached!
      return :wait if transitional?
      case status
      when :attached  then                             return true
      when :detached  then volume.try_to_detach(node); return :wait
      when :away      then try_to_create_volume;       return :wait
      else raise "Undefined state #{status.inspect} for #{self.inspect}"
      end
    end

    def delete_if_has_recent_snapshot!()
      if    status != "available"
        Log.info "Not removing #{id}: volume is #{status}"
        return
      elsif ! has_recent_snapshot?
        Log.info "Not removing #{id}: #{newest_snapshot ? "{newest_snapshot.description} is too old" : "no snapshot exists"}"
        return
      else
        Log.info "Deleting #{id}: have recent snapshot #{newest_snapshot.description}"
        Wucluster.ec2.delete_volume :volume_id => self.id
      end
    end

    def delete_old_snapshots
      # order by date
      old_snapshots = snapshots.sort_by(&:created_at)
      old_snapshots = old_snapshots.find_all{|snapshot| snapshot.status == "completed"}
      # remove the last
      newest = old_snapshots.pop
      Log.info "Keeping  #{newest.description}" if newest
      old_snapshots.each do |snapshot|
        snapshot.delete!
      end
    end

    # Summary name for this volume
    # Ex:  gibbon+master+01+00+/dev/sdh+/mnt/home+vol-1cfa0475
    def handle
      [cluster, role, "%02d"%node_idx, "%02d"%node_vol_idx, device, mount_point, volume_id].join("+")
    end
    # readable-ish description
    def description
      # "%-15s\tvolume for\t%15s\t%-7s\tnode #\t%7d\t%7d" % [mount_point, cluster, role, node_idx, node_vol_idx]
      handle.gsub(/\+/,"\t")
    end
    # recreate volume from handle
    def self.from_handle handle
      self.new *handle.split("+", self.keys.length)
    end

    def self.find volume_id
      all[volume_id]
    end

    #
    # Delegate stuff to the contained volume
    #

    def volume
      Ec2Volume.find(volume_id)
    end

    def size()          volume.size          end
    def from_snapshot() volume.from_snapshot end
    def region()        volume.region        end
    def state()         volume.state         end
    def created_at()    volume.created_at    end

    def detach!()
      volume.detach! if volume
    end
    def delete_volume_if_has_recent_snapshot!
      if volume
        volume.delete_if_has_recent_snapshot!
      else
        Log.info "Skipping #{volume_id}: not in existence"
      end
    end
    def attached?()
      volume && volume.attached?
    end
    def snapshots()
      volume ? volume.snapshots : []
    end
    def newest_snapshot()
      snapshots.sort_by(&:created_at).last
    end
    def create_snapshot
      if (!volume) then Log.info "Skipping new snapshot for #{description}: no volume" ; return end
      if newest_snapshot && newest_snapshot.recent?
        Log.info "Skipping new snapshot for #{volume_id}: #{newest_snapshot.description}"
        return
      end
      volume.create_snapshot
    end

    #
    # Snapshot
    #

    # Create a snapshot of the volume, including metadata in
    # the description to make it recoverable
    def create_snapshot options={}
      Log.info "Creating snapshot for #{id} as #{mount_handle}"
      Wucluster.ec2.create_snapshot options.merge(:volume_id => self.id, :description => mount_handle   )
    end

    def newest_snapshot
      snapshots.sort_by(&:created_at).find_all(&:completed?).last
    end
    def has_recent_snapshot?
      newest_snapshot && newest_snapshot.recent?
    end

    # List Associated Snapshots
    def snapshots
      Wucluster::Ec2Snapshot.for_volume id
    end

  end
end

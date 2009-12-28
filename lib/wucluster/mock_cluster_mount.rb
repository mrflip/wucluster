# ===========================================================================
#
# Mocks
#

module Wucluster

  class MockCluster < Cluster
    cattr_accessor :last_id; self.last_id = 0
    def load_mounts!
      @mounts = {}
      5.times do
        vol_id = 'vol_' + (self.last_id += 1).to_s
        mount = MockMount.new(vol_id)
        @mounts[vol_id] = mount
      end
      @mounts
    end
    def load_nodes!
      @nodes = {}
      5.times do
        instance_id = 'inst_' + (self.last_id += 1).to_s
        node = MockNode.new(instance_id)
        @nodes[instance_id] = node
      end
      @nodes
    end
  end

  class MockInstance < Ec2Instance
    include MockEC2Device
    attr_accessor :status, :id
    def initialize id
      self.id = id
    end
  end

  class MockNode < Node
    include MockEC2Device
    attr_accessor :instance
    delegate :status, :attach!, :attached?, :delete!, :deleted?, :to => :instance
    def initialize instance_id
      self.instance = MockInstance.new(instance_id)
    end
    def instantiate!
      p [:instantiate, status, instance]
      self.instance.status = :instantiated
    end
    def instantiated?
      status == :instantiated
    end
    def ready?
      p status
      instantiated?
    end
  end

  class MockVolume < Ec2Volume
    include MockEC2Device
    attr_accessor :status, :vol_id
    def initialize vol_id
      self.status = nil
      self.vol_id = vol_id
    end
    def to_s
      [vol_id, status,
        @transition_timer ? @transition_timer.remaining : nil,
        @transition_timer ? @transition_timer.finished? : nil,
      ].compact.map(&:to_s).join(" ")
    end

    def instantiate! vol_id
      return if [:instantiating, :instantiated, :attaching, :attached, :detaching, :detached].include?(status)
      start_transition :instantiating
      Log.debug "FIXME instantiate #{self}"
    end
    def attach!
      return if [:attaching, :attached].include?(status)
      raise "can't attach: #{status}" if [:deleting, :deleted].include?(status)
      start_transition :attaching
      Log.debug "FIXME attach #{self}"
    end
    def detach!
      return if [:detaching, :detached, :deleting, :deleted].include?(status)
      start_transition :detaching
    end
    def delete!
      return if [:deleting, :deleted].include?(status)
      start_transition :deleting
      Log.debug "FIXME delete #{self}"
    end

    def instantiated?
      self.status = :instantiated  if status == :instantiating && @transition_timer.finished?
      [:instantiated, :detaching, :detached, :attaching, :attached].include?(status)
    end
    def attached?
      self.status = :attached      if status == :attaching     && @transition_timer.finished?
      [:attached].include?(status)
    end
    def detached?
      self.status = :detached      if status == :detaching     && @transition_timer.finished?
      [:deleted, :deleting, :detached].include?(status)
    end
    def deleted?
      self.status = :deleted       if status == :deleting      && @transition_timer.finished?
      [:deleted].include?(status)
    end
  end

  class MockMount < Mount
    include MockEC2Device
    attr_accessor :volume, :vol_id
    def initialize vol_id
      self.vol_id = vol_id
    end

    def instantiate!
      self.volume ||= MockVolume.new(vol_id)
      volume.instantiate! vol_id
    end
  end

  class MockSnapshot # < Ec2Snapshot
    include MockEC2Device
    attr_accessor :status, :volume, :created_at
    cattr_accessor :snapshots
    self.snapshots = {}
    SNAPSHOT_RECENTNESS_TIME = 2 * 60 * 60 # two hours

    def initialize volume
      self.volume = volume
      start_transition :snapshotting
      self.created_at = Time.now + @transition_timer.remaining # kludge
    end
    def to_s
      [Time.now - created_at, @transition_timer.finished?, status, snapshotted?, recent?]
    end
    def recent?
      snapshotted? && ( (Time.now - self.created_at) < SNAPSHOT_RECENTNESS_TIME )
    end

    def snapshotted?
      self.status = :snapshotted if status == :snapshotting && @transition_timer.finished?
      [:snapshotted].include?(status)
    end
    def self.get_last_snapshot volume
      self.snapshots[volume.vol_id]
    end
    def self.create volume
      self.snapshots[volume.vol_id] ||= self.new(volume)
    end
  end

end

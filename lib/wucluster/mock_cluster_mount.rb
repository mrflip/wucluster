# ===========================================================================
#
# Mocks
#

module Wucluster
  MAX_TRIES = 14

  #
  # Simulates an event that takes a random amount of time
  #
  class RandomCountdownTimer
    # range of times to simulate
    attr_accessor :range
    # time the current iteration completes
    attr_accessor :finishes_at
    # initialize with the max amount of time to simulate -- will take an arbitrary
    # number of seconds between 0 and range
    def initialize range=2.0
      self.range = range
      start!
    end
    # starts a countdown timer
    def start!
      self.finishes_at = Time.now + self.range*rand() if ((!finishes_at) || finished?)
    end
    # true if the simulated even should report being done
    def finished?
      finishes_at && (Time.now > finishes_at)
    end
    def remaining
      finishes_at - Time.now
    end
  end

  module MockEC2Device
    private
    def start_transition transition_state
      @transition_timer ||= RandomCountdownTimer.new
      @transition_timer.start!
      self.state = transition_state
    end
  end

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
    attr_accessor :state, :id
    def initialize id
      self.id = id
    end
  end

  class MockNode < Node
    include MockEC2Device
    attr_accessor :instance
    delegate :state, :attach!, :attached?, :delete!, :deleted?, :to => :instance
    def initialize instance_id
      self.instance = MockInstance.new(instance_id)
    end
    def instantiate!
      p [:instantiate, state, instance]
      self.instance.state = :instantiated
    end
    def instantiated?
      state == :instantiated
    end

    def ready?
      p state
      instantiated?
    end
  end

  class MockVolume < Ec2Volume
    include MockEC2Device
    attr_accessor :state, :vol_id
    def initialize vol_id
      self.state = nil
      self.vol_id = vol_id
    end
    def status
      [vol_id, state,
        @transition_timer ? @transition_timer.remaining : nil,
        @transition_timer ? @transition_timer.finished? : nil,
      ].compact.map(&:to_s).join(" ")
    end

    def detach!
      return if [:detaching, :detached, :deleting, :deleted].include?(state)
      start_transition :detaching
    end
    def attach!
      return if [:attaching, :attached].include?(state)
      raise "can't attach: #{state}" if [:deleting, :deleted].include?(state)
      start_transition :attaching
      Log.debug "FIXME attach #{status}"
    end
    def delete!
      return if [:deleting, :deleted].include?(state)
      start_transition :deleting
      Log.debug "FIXME delete #{status}"
    end
    def instantiate! vol_id
      return if [:instantiating, :instantiated, :attaching, :attached, :detaching, :detached].include?(state)
      start_transition :instantiating
      Log.debug "FIXME instantiate #{status}"
    end

    def instantiated?
      self.state = :instantiated  if state == :instantiating && @transition_timer.finished?
      [:instantiated, :detaching, :detached, :attaching, :attached].include?(state)
    end
    def detached?
      self.state = :detached      if state == :detaching     && @transition_timer.finished?
      [:deleted, :deleting, :detached].include?(state)
    end
    def attached?
      self.state = :attached      if state == :attaching     && @transition_timer.finished?
      [:attached].include?(state)
    end
    def deleted?
      self.state = :deleted       if state == :deleting      && @transition_timer.finished?
      [:deleted].include?(state)
    end
  end

  class MockMount < Mount
    include MockEC2Device
    attr_accessor :volume, :vol_id
    delegate :state, :attach!, :attached?, :instantiated?, :delete!, :deleted?, :to => :volume
    delegate :size,  :region, :state, :created_at, :to => :volume
    def initialize vol_id
      self.vol_id = vol_id
    end
    def instantiate!
      self.volume ||= MockVolume.new(vol_id)
      volume.instantiate! vol_id
    end
    def status
      "#{volume && volume.status}"
    end

    def ready?
      instantiated? && attached?
    end
  end

  class MockSnapshot # < Ec2Snapshot
    include MockEC2Device
    attr_accessor :state, :volume, :created_at
    cattr_accessor :snapshots
    self.snapshots = {}
    SNAPSHOT_RECENTNESS_TIME = 2 * 60 * 60 # two hours

    def initialize volume
      self.volume = volume
      start_transition :snapshotting
      self.created_at = Time.now + @transition_timer.remaining # kludge
    end
    def status
      [Time.now - created_at, @transition_timer.finished?, state, snapshotted?, recent?]
    end
    def recent?
      snapshotted? && ( (Time.now - self.created_at) < SNAPSHOT_RECENTNESS_TIME )
    end

    def snapshotted?
      self.state = :snapshotted if state == :snapshotting && @transition_timer.finished?
      [:snapshotted].include?(state)
    end
    def self.get_last_snapshot volume
      self.snapshots[volume.vol_id]
    end
    def self.create volume
      self.snapshots[volume.vol_id] ||= self.new(volume)
    end
  end

end

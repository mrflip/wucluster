module Wucluster
  #
  # Cluster holds our idea of a hadoop cluster,
  # as embodied in the hadoop-ec2 config files
  #
  class Cluster
    ::Settings.define :aws_availability_zone, :default => 'us-east-1d', :description => "default availability zone for the cluster. For a bunch of good reasons, all parts of a cluster should be in the same availability zone"
    attr_accessor :name
    attr_accessor :availability_zone

    def initialize name, availability_zone = nil
      self.name              = name.to_sym
      self.availability_zone = availability_zone || Settings.aws_availability_zone
    end

    def to_s
      [ self.class, self.name,
        mounts.first.class, mounts.map(&:to_s).join(', ')
      ].map(&:to_s).join(" - ")
    end

    #
    # launch the cluster. A launched cluster is a fully armed and operational
    # battlestation. Right now, same as #mount! -- but it's possible other
    # assertions could be added.
    #
    def launch!
      mount!
    end
    # A launched cluster is a fully armed and operational battlestation. Right
    # now, same as #mount! -- but it's possible other assertions could be added.
    def launched?
      mounted?
    end

    # terminate this cluster:
    # * ensure all mounts are separated
    # * ensure all mounts are snapshotted
    # * put away all nodes and put away all mounts
    def terminate!
      separate!
      snapshot!
      delete!
    end
    # a cluster is away if all its nodes and mounts are away (no longer running)
    def terminated?
      nodes.all?(&:terminated?) && mounts.all?(&:terminated?)
    end

    # instantiate the cluster by ensuring all nodes and all mounts are instantiated
    def instantiate!
      repeat_until :instantiated? do
        nodes.each(&:instantiate!)
        mounts.each(&:instantiate!)
        Log.info "Instantiating #{self}"
      end
    end
    # are all the nodes and mounts instantiated?
    def instantiated?
      nodes.all?(&:instantiated?) && mounts.all?(&:instantiated?)
    end

    def attach!
      instantiate!
      repeat_until :attached? do
        mounts.each(&:attach!)
        Log.info "Attaching #{self}"
      end
    end
    # are all mounts attached to their nodes?
    def attached?
      instantiated? && mounts.all?(&:attached?)
    end

    # mount the cluster: #attach! and then demand all mounts are mounted within
    # their node.
    def mount!
      attach!
      repeat_until :mounted? do
        mounts.each(&:mount!)
        Log.info "Mounting #{self}"
      end
    end
    # are all mounts attached to their nodes?
    def mounted?
      attached? && mounts.all?(&:mounted?)
    end

    # mount the cluster: #attach! and then demand all mounts are mounted within
    # their node.
    def unmount!
      repeat_until :unmounted? do
        mounts.each(&:unmount!)
        Log.info "Mounting #{self}"
      end
    end
    # All mounts are unmounted on their nodes
    def unmounted?
      mounts.all?(&:unmounted?)
    end

    # Ask each mount to separate from its node
    def separate!
      unmount!
      repeat_until :separated? do
        mounts.each(&:separate!)
        Log.info "Separating #{self}"
      end
    end
    # are all mounts separated from their nodes?
    def separated?
      unmounted? && mounts.all?(&:separated?)
    end

    # Ask each mount to create a snapshot of its volume, including metadata in
    # to make it recoverable
    def snapshot!
      separate!
      repeat_until :recently_snapshotted? do
        mounts.each(&:snapshot!)
        Log.info "Snapshotting #{self}"
      end
    end
    # have all mounts been recently snapshotted?
    def recently_snapshotted?
      mounts.all?(&:recently_snapshotted?)
    end

    # Ask each mount to delete its volume
    def delete!
      raise "Tried to delete while not separated"                  if (! separated?)
      raise "out of order - tried to delete while not snapshotted" if (! recently_snapshotted?)
      repeat_until :deleted? do
        mounts.each(&:delete!)
        nodes.each( &:delete!)
        Log.info "Deleting #{self}"
      end
    end
    # have all mounts been deleted?
    def deleted?
      mounts.all?(&:deleted?) && nodes.all?(&:deleted?)
    end

  protected
    # repeat_until test, [sleep_time]
    #
    # * runs block
    # * tests for completion by calling (on self) the no-arg method +test+
    # * if the test fails, sleep for a bit...
    # * ... and then try again
    #
    # will only attempt MAX_TRIES times
    def repeat_until test, &block
      MAX_TRIES.times do
        yield
        break if self.send(test)
        sleep SLEEP_TIME
      end
    end
  end
end

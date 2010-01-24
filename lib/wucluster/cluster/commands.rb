module Wucluster
  class Cluster

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

    # ===========================================================================
    #
    # Sub-operations
    #
    # These implement the concrete steps taken to produce the goal operations above

    # instantiate the cluster by ensuring all nodes and all mounts are instantiated
    def create!
      repeat_until :created? do
        nodes.each(&:create!)
        mounts.each(&:create!)
        Log.info "Instantiating #{self}"
      end
    end
    # are all the nodes and mounts created?
    def created?
      nodes.all?(&:created?) && mounts.all?(&:created?)
    end

    def attach!
      repeat_until :attached? do
        Log.info "Attaching #{self}"
        mounts.each(&:attach!)
      end
    end
    # are all mounts attached to their nodes?
    def attached?
      created? && mounts.all?(&:attached?)
    end

    # mount the cluster: #attach! and then demand all mounts are mounted within
    # their node.
    def mount!
      repeat_until :mounted? do
        Log.info "Mounting #{self}"
        mounts.each(&:mount!)
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
        Log.info "Unmounting #{self}"
        mounts.each(&:unmount!)
      end
    end
    # All mounts are unmounted on their nodes
    def unmounted?
      mounts.all?(&:unmounted?)
    end

    # Ask each mount to separate from its node
    def separate!
      repeat_until :separated? do
        Log.info "Separating #{self}"
        mounts.each(&:separate!)
      end
    end
    # are all mounts separated from their nodes?
    def separated?
      unmounted? && mounts.all?(&:separated?)
    end

    # Ask each mount to create a snapshot of its volume, including metadata in
    # to make it recoverable
    def snapshot!
      repeat_until :recently_snapshotted? do
        Log.info "Snapshotting #{self}"
        mounts.each(&:snapshot!)
      end
    end
    # have all mounts been recently snapshotted?
    def recently_snapshotted?
      mounts.all?(&:recently_snapshotted?)
    end

    # Ask each mount to delete its volume
    def delete!
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
      Settings.max_tries.times do
        yield
        break if self.send(test)
        sleep Settings.sleep_time
      end
    end
  end
end

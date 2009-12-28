module Wucluster
  #
  # Cluster holds our idea of a hadoop cluster,
  # as embodied in the hadoop-ec2 config files
  #
  Cluster = Struct.new(:name) unless defined?(Cluster)
  Cluster.class_eval do
    cattr_accessor :all
    self.all = {}
    def initialize _name, *args
      super _name, *args
      self.name = _name.to_sym
      # raise "duplicate cluster #{name}" if self.class.all[name]
      self.class.all[name] = self
    end

    def to_s
      [ self.class, self.name,
        # mounts.first.class, mounts.map(&:to_s).join(', ')
      ].map(&:to_s).join(" - ")
    end

    # make the cluster ready: all its nodes and mounts are created, available and attached
    def make_ready!
      instantiate!
      attach!
    end
    # a cluster is ready when all its nodes and mounts are ready
    # (created, available, and attached)
    def ready?
      are_all(nodes, &:ready?) && are_all(mounts, &:ready?)
    end

    # Put away this cluster:
    # * ensure all mounts are separated
    # * ensure all mounts are snapshotted
    # * put away all nodes and put away all mounts
    def put_away!
      separate!
      snapshot!
      delete!
    end
    # a cluster is away if all its nodes and mounts are away (no longer running)
    def away?
      are_all(nodes, &:away?) && are_all(mounts, &:away?)
    end

    # instantiate the cluster by ensuring all nodes and all mounts are instantiated
    def instantiate!
      attempt_waiting_until :instantiated? do
        nodes.each(&:instantiate!)
        mounts.each(&:instantiate!)
        Log.info "Instantiating #{self}"
      end
    end
    # are all the nodes and mounts instantiated?
    def instantiated?
      are_all(nodes, &:instantiated?) && are_all(mounts, &:instantiated?)
    end

    def attach!
      attempt_waiting_until :attached? do
        mounts.each(&:attach!)
        Log.info "Attaching #{self}"
      end
    end
    # are all mounts attached to their nodes?
    def attached?
      are_all(mounts, &:attached?)
    end

    # Ask each mount to separate from its node
    def separate!
      attempt_waiting_until :separated? do
        mounts.each(&:separate!)
        Log.info "Separating #{self}"
      end
    end
    # are all mounts separated from their nodes?
    def separated?
      are_all(mounts, &:separated?)
    end

    # Ask each mount to create a snapshot of its volume, including metadata in
    # to make it recoverable
    def snapshot!
      raise "out of order - tried to snapshot while not separated" if (! separated?)
      attempt_waiting_until :recently_snapshotted? do
        mounts.each(&:snapshot!)
        Log.info "Snapshotting #{self}"
        Log.info MockSnapshot.snapshots.values.map(&:to_s).join(' - ')
      end
    end
    # have all mounts been recently snapshotted?
    def recently_snapshotted?
      are_all(mounts, &:recently_snapshotted?)
    end

    # Ask each mount to delete its volume
    def delete!
      raise "Tried to delete while not separated"                  if (! separated?)
      raise "out of order - tried to delete while not snapshotted" if (! recently_snapshotted?)
      attempt_waiting_until :deleted? do
        mounts.each(&:delete!)
        nodes.each(&:delete!)
        Log.info "Deleting #{self}"
      end
    end
    # have all mounts been deleted?
    def deleted?
      are_all(mounts, &:deleted?) && are_all(nodes,  &:deleted?)
    end

    #
    # Bookkeeping of nodes and mounts
    #

    # Hash of mounts, indexed by [role, node_idx, node_vol_idx]
    # Ex:
    #    p cluster.mounts[['master', 0, 0]]
    #    => #<struct Wucluster::Mount cluster="gibbon", role="master", node=<Wucluster::Node ...>, mount_idx=0, device="/dev/sdh", mount_point="/mnt/home", volume=#<Wucluster::Ec2Volume ...> >
    def all_mounts
      @all_mounts ||= load_mounts!
    end
    # flat list of mounts
    def mounts
      all_mounts.sort.map(&:last)
    end

    # Hash of nodes, indexed by [role, node_idx, node_vol_idx]
    # Ex:
    #    p cluster.nodes[['master', 0, 0]]
    #    => #<struct Wucluster::Node cluster="gibbon", role="master", idx=0, node=...>
    def all_nodes
      @all_nodes ||= load_nodes!
    end
    # flat list of nodes
    def nodes
      all_nodes.map(&:last)
    end

    # flat list of snapshots from all mounts
    def snapshots
      snaps = []
      mounts.each do |mount|
        snaps += mount.snapshots
      end
      snaps
    end

    # Turn the cluster_role_node_mount_tree into a flat list of mounts,
    # an hash indexed by [role,node_idx,node_vol_idx]
    # interface to cluster definition from cloudera config files
    def load_mounts!
      @all_mounts = {}
      cluster_role_node_mount_tree.each do |role, cluster_node_mounts|
        cluster_node_mounts.each_with_index do |mounts, node_idx|
          mounts.each_with_index do |mount, node_vol_idx|
            @all_mounts[[role, node_idx, node_vol_idx]] =
              Mount.new(name, role, node_idx, node_vol_idx, mount['device'], mount['mount_point'], mount['volume_id'])
          end
        end
      end
      @all_mounts
    end

  private
    # attempt_waiting_until test, [sleep_time]
    #
    # * runs block
    # * tests for completion by calling (on self) the no-arg method +test+
    # * if the test fails, sleep for a bit...
    # * ... and then try again
    #
    # will only attempt MAX_TRIES times
    def attempt_waiting_until test, &block
      MAX_TRIES.times do
        yield
        break if self.send(test)
        sleep SLEEP_TIME
      end
    end

    # the boolean "and" of calling block on each mount -- returns false if any
    # of the block calls returns false, true only if they are all true.
    def are_all collection, &block
      collection.each{|obj| return false if (! yield(obj)) }
      return true
    end

    # The raw cluster_role_node_volume_tree from the cloudera EC2 cluster file
    def cluster_role_node_mount_tree
      @cluster_role_node_mounts ||= JSON.load(File.open(HADOOP_EC2_DIR+"/ec2-storage-#{name}.json"))
    end
  end
end

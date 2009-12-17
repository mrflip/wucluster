
# class ClusterSm
#   include AASM
#
#   aasm_state :ready       # all volumes exist, all nodes exist, all are attached
#   aasm_state :detached    # all volumes exist, none are attached
#   aasm_state :snapshotted # all volumes exist, have recent snapshots
#   aasm_state :away        # all volumes deleted, have a snapshot
#
#   aasm_event
# end

#
# State machine for a cluster node
#
# A node can be
# * ready:        instance is active and all mounts are ready
# * detached:     instance is active and all mounts are detached
# * away:         instance is inactive and all mounts are away
# * semiattached: instance is active but some mounts are attached and others are detached
#
class NodeSm
  #
  # states
  #
  def status
    case
    when ready?        then return :ready
    when detached?     then return :detached
    when semiattached? then return :semiattached
    when away?         then return :away
    else raise "Invalid state #{self.inspect}" end
  end
  def ready?
    instance_active? && all_mounts_attached?
  end
  def detached?
    instance_active? && all_mounts_detached?
  end
  def semiattached?
    instance_active? && (! all_mounts_detached?) && (! all_mounts_attached?)
  end
  def away?
    (! instance_active?)
  end
  #
  #
  #
  # does the node have a running
  def instance_active?
    ! self.instance_id.blank?
  end
end

module Mocker
  def successful prob=0.8
    rand < prob
  end
end
class MockNode
  include Mocker
  attr_accessor :mounts
  def initialize
    self.mounts = [MockMount.new(self), MockMount.new(self)]
  end
  def try_to_inactivate
    return true if (! instance_active?)
    if successful(0.8)
      instance_id = nil
    end
  end
end

#
# State machine for a cluster mount
#
# A mount can be
# * ready:        volume active and is attached
# * (attaching)
# * (detaching)
# * detached:     volume active and is detached but no recent snapshot exists
# * (creating)
# * (deleting)
# * (snapshotting)
# * deletable:    volume active, detatched and a recent snapshot exists
# * away:         volume is away and a snapshot exists
# * raw:          volume is away and no snapshot exists
#
class MountSm
  def ready?
    volume_active? && volume_attached?
  end
  def detached?
    volume_active? && (! volume_attached?) && (! recent_snapshot_exists?)
  end
  def deletable?
    volume_active? && (! volume_attached?) && recent_snapshot_exists?
  end
  def away?
    (! volume_active?) && snapshot_exists?
  end
  def raw?
    (! volume_active?) && (! snapshot_exists?)
  end

  #
  # Imperatives
  #

  #
  def make_attached!
    return :wait if transitional?
    case status
    when :attached  then                             return true
    when :detached  then volume.try_to_detach(node); return :wait
    when :away      then try_to_create_volume;       return :wait
    else raise "Undefined state #{status.inspect} for #{self.inspect}"
    end
  end

  #
  def make_detached!
    return :wait if transitional?
    case status
    when :attached  then volume.try_to_attach(node); return :wait
    when :detached  then                             return true
    when :away      then try_to_create_volume;       return :wait
    else raise "Undefined state #{status.inspect} for #{self.inspect}"
    end
  end


end

class MockMount < MountSm
  include Mocker
  attr_accessor :node, :_volume_status
  def initialize node
    self.node           = node
    self._volume_status = [:attached, :detached, :away].random
  end

  def transitional?
    [:attaching, :detaching, :creating, :deleting, :snapshotting].include?(status)
  end

  def try_to_activate
  end
  def try_to_deactivate
    return true if (! volume_active?)
    if successful(0.8)
      self._attached = false
    end
  end
  def try_to_detach
    return true if (! volume_attached?)
    if successful(0.8)
      self._attached = false
    end
  end
  def volume_attached?
    _attached
  end
  def volume_active?
    _active
  end
end

class MockVolume
  include Mocker
end


class MockCluster
  include Mocker
end


class Array
  def random
    self[Kernel.rand(size)]
  end

  def random_subset(len=2)
    rs = []
    len.times { rs << random }
    rs
  end
end

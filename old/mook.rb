
# module Mocker
#   def successful prob=0.8
#     rand < prob
#   end
# end
# class MockNode
#   include Mocker
#   attr_accessor :mounts
#   def initialize
#     self.mounts = [MockMount.new(self), MockMount.new(self)]
#   end
#   def try_to_inactivate
#     return true if (! instance_active?)
#     if successful(0.8)
#       instance_id = nil
#     end
#   end
# end
#
# class Array
#   def random
#     self[Kernel.rand(size)]
#   end
#   def random_subset(len=2)
#     rs = []
#     len.times { rs << random }
#     rs
#   end
# end

# class MockCluster
#   include Mocker
# end
#
# class MockMount < MountSm
#   include Mocker
#   attr_accessor :node, :_volume_status
#   def initialize node
#     self.node           = node
#     self._volume_status = [:attached, :detached, :away].random
#   end
#   def transitional?
#     [:attaching, :detaching, :creating, :deleting, :snapshotting].include?(status)
#   end
#   def try_to_activate
#   end
#   def try_to_deactivate
#     return true if (! volume_active?)
#     if successful(0.8)
#       self._attached = false
#     end
#   end
#   def try_to_detach
#     return true if (! volume_attached?)
#     if successful(0.8)
#       self._attached = false
#     end
#   end
#   def volume_attached?
#     _attached
#   end
#   def volume_active?
#     _active
#   end
# end

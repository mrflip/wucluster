module Wucluster

  Node = Struct.new(
    :cluster,
    :role,
    :node_idx,
    :instance_id
    )
  Node.class_eval do
    cattr_accessor :all
    self.all = {}


  end
end

module Wucluster
  class Node
    # belongs to cluster
    attr_accessor :cluster
    # string identifying logical role
    attr_accessor :role
    # together with the role, uniquely identifies node in cluster
    attr_accessor :node_idx
    # AWS id for the concrete instance if any
    attr_accessor :instance_id

    def instantiate!
    end
    def instantiated?
    end

    def terminate!
    end
    def terminated?
    end
  end
end

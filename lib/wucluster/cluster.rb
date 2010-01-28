require 'wucluster/cluster/components'
require 'wucluster/cluster/layout'
require 'wucluster/cluster/catalog'
require 'wucluster/cluster/commands'
module Wucluster
  #
  # Cluster holds our idea of a hadoop cluster,
  # as embodied in the hadoop-ec2 config files
  #
  class Cluster
    # Name for this cluster. Security groups, key names and other attributes are
    # defined from this name.
    attr_accessor :name
    # availability zone for cluster. Cluster elements must all share an
    # availability zone
    attr_accessor :availability_zone
    # default image_id for cluster nodes
    attr_accessor :image_id
    # default instance type for cluster nodes
    attr_accessor :instance_type

    # cluster_graph = [
    #   [:launched?,        [:mounts_launched?, :nodes_launched?], nil],
    #   [:nodes_launched?,  nil, :launch_nodes!],
    #   [:mounts_launched?, nil, :launch_mounts!],
    # ]

    # construct new cluster
    def initialize name
      self.name = name.to_sym
    end

    # pull in cluster's logical layout, and pair up any
    # existing instances and volumes
    def load!
      load_layout
      # catalog_existing_volumes!
      # catalog_existing_instances!
    end

    # find cluster if it exists,
    # or create cluster
    def self.new name, *args
      listing[name.to_sym] ||= super(name, *args)
    end
    # existing clusters
    def self.listing
      @listing ||= {}
    end
    # look up cluster instance
    def self.find name
      listing[name.to_sym]
    end

    #
    def roles
      all_nodes.keys.map(&:first).uniq
    end
    #
    def roles_count
      roles_count = Hash.new{|h,k| 0 }
      all_nodes.keys.each do |role, node_idx|
        roles_count[role] += 1
      end
      roles_count
    end

    #
    def to_s
      %Q{#<#{self.class} #{self.name} nodes: #{roles_count.inspect} #{mounts.length} mounts>}
    end
  end
end

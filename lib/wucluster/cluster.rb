require 'wucluster/cluster/description'
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

    def initialize name, availability_zone = nil
      self.name              = name.to_sym
      self.availability_zone = availability_zone || Settings.aws_availability_zone
    end

    def roles
      all_nodes.keys.map(&:first).uniq
    end
    def roles_count
      roles_count = Hash.new{|h,k| 0 }
      all_nodes.keys.each do |role, node_idx|
        roles_count[role] += 1
      end
      roles_count
    end

    def to_s
      %Q{<##{self.class} #{self.name} nodes: #{roles_count.inspect} #{mounts.length} mounts>}
    end
  end
end

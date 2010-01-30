require 'wucluster/cluster/components'
require 'wucluster/cluster/layout'
require 'wucluster/cluster/catalog'
module Wucluster
  #
  # Cluster holds our idea of a hadoop cluster,
  # as embodied in the hadoop-ec2 config files
  #
  class Cluster
    include DependencyGraph

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

    # construct new cluster
    def initialize name
      self.name = name.to_sym
    end

    #
    # launch the cluster. A launched cluster is a fully armed and operational
    # battlestation. Right now, same as #mount! -- but it's possible other
    # assertions could be added.
    #
    def launch!
      repeat_until(:launched?) do
        instances.each{|inst| inst.launch! }
        volumes.each{  |vol|  vol.launch! }
      end
    end
    # A launched cluster is a fully armed and operational battlestation. Right
    # now, same as #mount! -- but it's possible other assertions could be added.
    def launched?
      instances.all?(&:launched?) && volumes.all?(&:launched?)
    end

    def separate!
      repeat_until(:separated?) do
        volumes.each{  |vol| vol.detach! }
      end
    end
    def separated?
      volumes.all?(&:detached?)
    end

    # terminate this cluster:
    # * ensure all mounts are separated
    # * ensure all mounts are snapshotted
    # * put away all nodes and put away all mounts
    def put_away!
      repeat_until(:put_away?) do
        instances.each{|inst| inst.put_away! }
        volumes.each{  |inst| inst.put_away! }
      end
    end
    # a cluster is away if all its instances and volumes are away (no longer running)
    def put_away?
      instances.all?(&:put_away?) && volumes.all?(&:put_away?)
    end

    # Bulk reload the state of all volumes, instances, SecurityGroups and Keypairs
    def refresh!
      [ Volume, Instance, Snapshot, SecurityGroup, Keypair ].each{|klass| klass.load_all! }
    end

    # pull in cluster's logical layout, and pair up any
    # existing instances and volumes
    def load!
      load_layout
      refresh!
      adopt_existing_volumes!
      adopt_existing_instances!
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
    def to_s
      %Q{#<#{self.class} #{self.name} nodes: #{roles_count.inspect} #{mounts.length} mounts>}
    end

  end
end

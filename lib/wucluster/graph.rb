#!/usr/bin/env ruby
require 'set'

class Graph
  attr_reader :dependencies
  attr_reader :dependency_paths
  attr_accessor :dependency_met

  def initialize dependencies
    @dependencies = dependencies
    @dependency_met = Set.new
  end

  def bfs

  end

  def become goal, level=0
    raise "oops" if level > 20
    return true if met?(goal)
    found, preconditions, next_step = dependencies.assoc(goal)
    preconditions = [preconditions].flatten.compact
    warn "No origin for #{goal} goal" unless found
    puts "%-40s %s" % [" "*level + goal.to_s, preconditions.inspect] unless preconditions.empty?
    success = preconditions.map do |precondition|
      become precondition, level+2
    end
    # p [goal, next_step, preconditions.map{|cond| [cond, met?(cond)]}, dependency_met]
    if success.all?
      puts "%-40s" % [" "*level + '  => ' + next_step.to_s] if next_step
      self.met! goal
      puts "  #{" "*level}met #{goal.to_s.gsub(/\?/,'.')}" if met?(goal)
    end
    met?(goal)
  end

  def met! goal
    return unless rand(10) < 5
    self.dependency_met << goal
  end

  def met? goal
    self.dependency_met.include? goal
  end
end

cluster_graph = [
  [:launched?,        [:mounts_launched?, :nodes_launched?], nil],
  [:nodes_launched?,  nil, :launch_nodes!],
  [:mounts_launched?, nil, :launch_mounts!],
]

mount_graph = [
  [:away?,          nil,                         nil],
  [:creating?,      :away?,                      :create!],
  [:created?,       :creating?,                  :wait],
  # [:node_running?,  nil,                         :node_create!],
  [:attaching?,    [:created?,  :node_running?], :attach!],
  [:attached?,      :attaching?,                 :wait],
  [:mounted?,       :attached?,                  :mount!],
  [:completed?,      :mounted?,                   nil],

  [:node_away?, nil, nil],
  [:node_starting?,      :node_away?,                        :node_start!],
  [:node_running?,       :node_starting?,                    :wait],
  [:node_completed?,      :node_created?,                     nil],
]


node_graph = [
  [:away?, nil, nil],
  [:running?,      :away?,                        :create!],
  [:created?,       :running?,                    :wait],
  [:completed?,      :created?,                     nil],
]

# ===========================================================================

migration_graph = [
  [:raw_file_exists?, nil, nil],
  [:raw_file_alone?,   :raw_file_exists?,                 :remove_non_raw!],
  [:checksummed?,      :raw_file_alone?,                  :checksum_raw!],
  [:pkgd?,             :checksummed?,                     :pkg_and_remove!],
  [:pkg_checksummed?,   :pkgd?,                            :checksum_pkg!],
  [:pkg_on_s3?,        [:pkgd?, :pkg_checksummed?],       :copy_pkgd_to_s3!],
  [:pkg_removed?,      :pkg_removable?,                   :remove_local_pkg!],
  [:pkgsum_removed?,   [:pkg_checksummed?, :pkg_removed?], :remove_local_pkgsum!],
  [:checksum_on_s3?,   :checksummed?,                     :copy_checksum_to_s3!],
  [:checksum_removed?, :checksum_on_s3?,                  :remove_local_checksum!],
  [:completed?, [:pkg_on_s3?, :checksum_on_s3?, :pkg_removed?, :checksum_removed?, :pkgsum_removed?], nil],

  #
  [:pkg_removable?, [:pkgd?, :pkg_on_s3?, :pkg_checksummed?, :pkg_and_s3_are_identical?], nil],
  [:pkg_and_s3_are_identical?, [:pkgd?, :pkg_on_s3?, :pkg_checksummed?], nil],

]

graph = Graph.new(mount_graph)
graph.dependency_met += [:away?, :node_away?]
10.times do
  graph.become :completed?
  break if graph.met? :completed?
end


# Graph.new(migration_graph).become :completed?

def pkg_removable?
  [:pkgd?, :pkg_checksummed?]
end


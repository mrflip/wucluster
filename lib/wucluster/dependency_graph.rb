#!/usr/bin/env ruby
require 'set'

module DependencyGraph
  # list of triples:
  #    [goal,  [...preconditions...],  next_action]
  # that outline workflow.
  #
  # It is *not* assumed that the goal is met after next_action is taken,
  # since actions are assumed to be unreliable.
  attr_reader :dependencies
  # maximum path  through graph to allow
  MAX_DEPENDENCY_GRAPH = 20 unless defined?(MAX_DEPENDENCY_GRAPH)

  # Retrieve the preconditions and next step for the given goal.
  #
  # @param goal [Symbol] goal to reach
  def dependencies_for goal
    found, preconditions, next_action = dependencies.assoc(goal)
    preconditions = [preconditions].flatten.compact
    warn "No origin for #{goal} goal" unless found
    [found, preconditions, next_action]
  end

  # Tries to reach the given state.
  # * assert each precondition in turn by recursively calling #become.
  # * if all preconditions are met,
  # * try the next step
  #
  # Asking to become a given state *doesn't* mean you'll reach that state, it
  # only promises that it will attempt to move closer to the goal. A call chain
  # to become will only take one unreliable step: if the system isn't in the
  # goal state after the call to next_action, no further actions happen in that
  # branch of the tree.
  #
  # @param goal  [Symbol] the state assertion to reach
  # @return true if the goal was met
  def become goal, level=0
    return true if met?(goal)
    raise "reaching goal #{goal} would need too many steps" if level > MAX_DEPENDENCY_GRAPH
    found, preconditions, next_action = dependencies_for(goal)
    # attempt each precondition in turn
    success = preconditions.map do |precondition|
      become precondition, level+1
    end
    # if all preconditions are met, try next step
    take_next_action(next_action, goal) if success.all?
    return met?(goal)
  end

  def take_next_action next_action, goal
    self.send(next_action)
  end

  def met? goal
    self.send(goal)
  end
end

class DependencyGraphSim
  include DependencyGraph
  # fakes the dependency state
  attr_accessor :dependency_met
  # distribute the level out to rest of object (kludge)
  attr_accessor :level
  # probability a goal
  CHANCE_GOAL_REACHED = 0.4

  def initialize dependencies
    self.dependencies = dependencies
    @dependency_met = Set.new
  end

  def become goal, level=0
    self.level = level
    super(goal, level)
  end

  def dependencies_for goal
    found, preconditions, next_action = super(goal)
    puts "%-40s %s" % [" "*2*level + goal.to_s, preconditions.inspect] unless preconditions.empty?
    [found, preconditions, next_action]
  end

  def take_next_action next_action, goal
    # instead of calling out to next step, just fake it.
    puts "%-40s" % [" "*2*level + '  => ' + next_action.to_s] if next_action
    self.met! goal
    puts "  #{" "*2*level}met #{goal.to_s.gsub(/\?/,'.')}" if met?(goal)
  end

  # fakes an unreliable process:
  def met! goal
    return unless rand < CHANCE_GOAL_REACHED
    self.dependency_met << goal
  end

  #
  def met? goal
    self.dependency_met.include? goal
  end
end

#!/usr/bin/env ruby
require 'set'

module Wucluster
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
      take_next_action(next_action, goal) if next_action && success.all?
      return met?(goal)
    end

    # Invokes the next action: calls the corresponding method on self.
    #
    # @example
    #   take_next_action :launch_missiles!
    #   # => tries to launch missiles
    def take_next_action next_action, goal
      Log.info [next_action, self].inspect
      return if next_action == :wait
      self.send(next_action)
    end

    # Was the goal met? Calls the corresponding method on self.
    #
    # @example
    #   met? :created?
    #   # => returns value of self.created?
    def met? goal
      self.send(goal)
    end

    protected
    # repeat_until test, [sleep_time]
    #
    # * runs block
    # * tests for completion by calling (on self) the no-arg method +test+
    # * if the test fails, sleep for a bit...
    # * ... and then try again
    #
    # will only attempt MAX_TRIES times
    def repeat_until goal, &block
      Settings.max_tries.times do
        yield
        break if self.send(goal)
        sleep Settings.sleep_time
        refresh!
      end
      self.send(goal)
    end

    # returns status of goal
    #
    # @example
    #   become :attached?
    #   # => repeatedly tries to become attached?, returns whether attached
    def become! goal
      repeat_until(goal){  become(goal) }
    end
  end
end

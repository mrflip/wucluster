#
# Simulate operation of a DependencyGraph -- just logs each operation (doesn't
# run it) and fakes each operation as unreliaable (by default, 40% likely to succeed).
#
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

module Wucluster
    # Effective -infinity
    LONG_TIME_AGO       = 10*365*24*60*60
  #
  # Simulates an event that takes a random amount of time
  #
  class RandomCountdownTimer
    # range of times to simulate
    attr_accessor :range
    # time the current iteration completes
    attr_accessor :finishes_at
    # initialize with the max amount of time to simulate -- will take an arbitrary
    # number of seconds between 0 and range
    def initialize range=2.0
      self.range = range
      start!
    end
    # starts a countdown timer
    def start!
      self.finishes_at = Time.now + self.range*rand() if ((!finishes_at) || finished?)
    end
    # true if the simulated even should report being done
    def finished?
      finishes_at && (Time.now > finishes_at)
    end
    def remaining
      finishes_at - Time.now
    end
  end

  module MockEC2Device
    private
    def start_transition transition_status
      @transition_timer ||= RandomCountdownTimer.new
      @transition_timer.start!
      self.status = transition_status
    end
  end
end

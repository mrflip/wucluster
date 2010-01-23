module Wucluster
  #
  # Cluster holds our idea of a hadoop cluster,
  # as embodied in the hadoop-ec2 config files
  #
  class Cluster
    ::Settings.define :aws_availability_zone, :default => 'us-east-1d', :description => "default availability zone for the cluster. For a bunch of good reasons, all parts of a cluster should be in the same availability zone"
    attr_accessor :name
    attr_accessor :availability_zone

    def initialize name, availability_zone = nil
      self.name              = name.to_sym
      self.availability_zone = availability_zone || Settings.aws_availability_zone
    end

    def to_s
      [ self.class, self.name,
        mounts.first.class, mounts.map(&:to_s).join(', ')
      ].map(&:to_s).join(" - ")
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
    def repeat_until test, &block
      MAX_TRIES.times do
        yield
        break if self.send(test)
        sleep SLEEP_TIME
      end
    end
  end
end

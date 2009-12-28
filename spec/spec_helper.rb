require 'rubygems'
# $LOAD_PATH.unshift(File.dirname(__FILE__))
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'spec'
require File.dirname(__FILE__)+'/../lib/wucluster'
module Wucluster
  SLEEP_TIME = 0.01
end

# require File.expand_path(File.dirname(__FILE__) + "/blueprints")

Spec::Runner.configure do |config|
  # config.before(:all)    { Sham.reset(:before_all)  }
  # config.before(:each)   { Sham.reset(:before_each) }
end

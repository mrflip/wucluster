$: << File.dirname(__FILE__)
require 'configliere'; Configliere.use :define
require 'AWS'
# require File.dirname(__FILE__)+'/AWS/EC2/snapshot'
# require File.dirname(__FILE__)+'/AWS/EC2/mock'
# require 'wukong/logger'
# require 'wucluster/mock'

module Wucluster
  Settings.define :sleep_time, :type => Float,   :default => 1.0,   :description => "How long to sleep between attempts"
  Settings.define :max_tries,  :type => Integer, :default => 15,    :description => "How many times to attempt an operation before giving up"
  Settings.define :access_key_id,                :required => true, :description => "Amazon AWS access key ID, found in your AWS console (http://bit.ly/awsconsole)"
  Settings.define :secret_access_key,            :required => true, :description => "Amazon AWS secret access key, found in your AWS console (http://bit.ly/awsconsole)"

  autoload :Cluster,     'wucluster/cluster'
  autoload :Mount,       'wucluster/mount'
  autoload :Node,        'wucluster/node'
  # autoload :Ec2Volume,   'wucluster/ec2_volume'
  # autoload :Ec2Instance, 'wucluster/ec2_instance'
  # autoload :Ec2Snapshot, 'wucluster/ec2_snapshot'
  # require 'wucluster/mock_cluster_mount'

  #
  # single point of access to AWS calls
  #
  def self.ec2
    @ec2 ||= AWS::EC2::Base.new(:access_key_id => Settings.access_key_id, :secret_access_key => Settings.secret_access_key)
  end
end

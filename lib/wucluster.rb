$: << File.dirname(__FILE__)
require 'logger'
require 'configliere'; Configliere.use :define, :config_file
require 'AWS'
Log = Logger.new $stderr unless defined?(Log)

Settings.define :sleep_time, :type => Float,   :default => 1.0,   :description => "How long to sleep between attempts"
Settings.define :max_tries,  :type => Integer, :default => 15,    :description => "How many times to attempt an operation before giving up"
Settings.define :aws_access_key_id,                :required => true, :description => "Amazon AWS access key ID, found in your AWS console (http://bit.ly/awsconsole)"
Settings.define :aws_secret_access_key,            :required => true, :description => "Amazon AWS secret access key, found in your AWS console (http://bit.ly/awsconsole)"
Settings.read("wucluster.yaml") # will look in ~/.configliere/wucluster.yaml
p Settings
Settings.resolve!

module Wucluster

  autoload :Cluster,     'wucluster/cluster'
  autoload :Mount,       'wucluster/mount'
  autoload :Node,        'wucluster/node'
  autoload :Ec2Proxy,    'wucluster/ec2_proxy'
  autoload :Ec2Volume,   'wucluster/ec2_volume'
  autoload :Ec2Instance, 'wucluster/ec2_instance'
  autoload :Ec2Snapshot, 'wucluster/ec2_snapshot'
  # require 'wucluster/mock_cluster_mount'

  #
  # single point of access to AWS calls
  #
  def self.ec2
    @ec2 ||= AWS::EC2::Base.new(:access_key_id => Settings.aws_access_key_id, :secret_access_key => Settings.aws_secret_access_key)
  end
end

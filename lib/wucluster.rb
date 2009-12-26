require 'json'
require 'yaml'
require 'wukong/extensions'
require 'wukong/extensions/hash_keys'
require 'AWS'
load File.dirname(__FILE__)+'/AWS/EC2/snapshot.rb'
load File.dirname(__FILE__)+'/AWS/EC2/mock.rb'
autoload :Log, 'wukong/logger'

module Wucluster
  CONFIG_DIR = ENV['HOME']+'/.hadoop-ec2'

  # autoload :Cluster,      'wucluster/cluster'
  # autoload :ClusterMount, 'wucluster/cluster_mount'
  # autoload :Ec2Volume,    'wucluster/ec2_volume'
  # autoload :Ec2Snapshot,  'wucluster/ec2_snapshot'

  #
  # single point of access to AWS calls
  #
  def self.ec2
    @ec2 ||= AWS::EC2::Base.new( :access_key_id => access_key_id, :secret_access_key => secret_access_key)
  end

  #
  # Configuration -- uses ~/.hadoop-ec2/s3config.yml (and not env. vars)
  #
  def self.config
    @config ||= YAML.load(File.open(Wucluster::CONFIG_DIR+'/s3config.yml')).symbolize_keys!
  end
  # the aws access_key_id, taken from the global config.
  def self.access_key_id
    config[:aws_access_key_id]
  end
  # the aws secret_access_key, taken from the global config.
  def self.secret_access_key
    config[:aws_secret_access_key]
  end
  # the aws account_id, taken from the global config
  def self.aws_account_id
    config[:aws_account_id]
  end

end

require 'json'
require 'yaml'
require 'wukong/extensions'
require 'wukong/extensions/hash_keys'
require 'AWS'
load File.dirname(__FILE__)+'/AWS/EC2/snapshot.rb'
autoload :Log, 'wucluster/logger'

module Wucluster
  CONFIG_DIR = ENV['HOME']+'/.hadoop-ec2'

  autoload :Cluster,      'wucluster/cluster'
  autoload :ClusterMount, 'wucluster/cluster_mount'
  autoload :Ec2Volume,    'wucluster/ec2_volume'
  autoload :Ec2Snapshot,  'wucluster/ec2_snapshot'

  def self.config
    @config ||= YAML.load(File.open(Wucluster::CONFIG_DIR+'/s3config.yml')).symbolize_keys!
  end

  def self.ec2
    @ec2 ||= AWS::EC2::Base.new(
      :access_key_id     => config[:aws_access_key_id],
      :secret_access_key => config[:aws_secret_access_key])
  end

end

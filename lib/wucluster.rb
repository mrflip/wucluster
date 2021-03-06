require 'AWS'               # gem install amazon-ec2
require 'AWS/EC2/overrides'
require 'json'
require 'logger'
#
Log = Logger.new $stderr unless defined?(Log)
require 'configliere'; Configliere.use :define, :config_file, :config_block
require 'extlib'
require 'wucluster/exceptions'
require 'wucluster/extensions'
require 'wucluster/ec2_proxy'

#
# Stateful operations on a persistent AWS cluster
#
# Wucluster lets you set up and tear down an AWS cluster
#
# Rather than describe a process to construct a cluster -- which requ
#
module Wucluster
  autoload :DependencyGraph, 'wucluster/dependency_graph'
  autoload :Cluster,         'wucluster/cluster'
  autoload :Volume,          'wucluster/volume'
  autoload :Instance,        'wucluster/instance'
  autoload :Snapshot,        'wucluster/snapshot'
  autoload :SecurityGroup,   'wucluster/security_group'
  autoload :Keypair,         'wucluster/keypair'

  #
  # single point of access to AWS calls
  #
  def self.ec2
    @ec2 ||= AWS::EC2::Base.new(:access_key_id => Settings.aws_access_key_id, :secret_access_key => Settings.aws_secret_access_key)
  end
end

Settings.define :sleep_time, :type => Float,   :default => 1.0,   :description => "How long to sleep between attempts"
Settings.define :max_tries,  :type => Integer, :default => 15,    :description => "How many times to attempt an operation before giving up"
Settings.define :aws_access_key_id,            :required => true, :description => "Amazon AWS access key ID -- found in your AWS console (http://bit.ly/awsconsole)"
Settings.define :aws_secret_access_key,        :required => true, :description => "Amazon AWS secret access key -- found in your AWS console (http://bit.ly/awsconsole)"
Settings.define :aws_account_id,               :required => true, :description => "Amazon AWS account ID, without dashes -- found in your AWS console (http://bit.ly/awsconsole)"
Settings.define :availability_zone,            :default => 'us-east-1d', :description => "default availability zone for the cluster. For a bunch of good reasons, all parts of a cluster should be in the same availability zone"
Settings.define :private_key_dir,              :required => true, :description => "Directory storing keypair private keys, each with the name 'keypair_name.pem'"
Settings.define :ssh_options,                  :default => '-i %(private_key)s -o StrictHostKeyChecking=no', :description => "Options to pass to the ssh program. The exact string '%(private_key)s' will be substituted with the corresponding keypair's private_key filename."
# Settings.define :cluster_definition_dir,        :default => ENV['HOME']+'/.hadoop-ec2', :required => true, :description => "Amazon AWS secret access key, found in your AWS console (http://bit.ly/awsconsole)"
Settings.define :clusters,                     :description => "Hash describing full layout of the cluster. See README for examples"

Settings.read("wucluster.yaml") # will look in ~/.configliere/wucluster.yaml
Settings.finally do |cfg|
  cfg[:private_key_dir].gsub!(/%\(home\)s/, ENV['HOME'])
  cfg[:ssh_options].gsub!(/%\(private_key\)s/, cfg[:private_key_dir])
end
Settings.resolve!

#!/usr/bin/env ruby
WUCLUSTER_DIR = File.expand_path(File.dirname(__FILE__))
$: << WUCLUSTER_DIR+'/../lib'
require 'rubygems'
require 'wucluster'

HADOOP_EC2_DIR = File.expand_path(File.dirname(__FILE__))

# # Cluster.new(:gibbon).put_away_volumes
# # Ec2Snapshot.list_all
# Ec2Volumes.list_all

p Wucluster::Ec2Volume.find 'vol-d5d826bc'

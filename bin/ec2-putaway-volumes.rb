#!/usr/bin/env ruby
WUCLUSTER_DIR = File.expand_path(File.dirname(__FILE__))
$: << WUCLUSTER_DIR+'/../lib'
require 'rubygems'
require 'wucluster'

HADOOP_EC2_DIR = File.expand_path(File.dirname(__FILE__))

# # Cluster.new(:gibbon).put_away_volumes
# # Ec2Snapshot.list_all
# Ec2Volumes.list_all

# vol = Wucluster::Ec2Volume.find 'vol-1cfa0475'
# p vol.snapshots

#p Wucluster::Ec2Snapshot.find 'snap-aabe02c3'
#p Wucluster::Ec2Snapshot.all


#!/usr/bin/env ruby
WUCLUSTER_DIR = File.expand_path(File.dirname(__FILE__))
$: << WUCLUSTER_DIR+'/../lib'
require 'rubygems'
require 'wucluster'

# module Wucluster
#   def self.ec2
#     @ec2 = AWS::EC2::Mock.new
#   end
# end

HADOOP_EC2_DIR = File.expand_path(ENV['HOME']+'/.hadoop-ec2')


# # Cluster.new(:gibbon).put_away_volumes
# # Snapshot.list_all
# Volumes.list_all

# vol = Wucluster::Volume.find 'vol-1cfa0475'
# p vol.snapshots

#p Wucluster::Snapshot.find 'snap-aabe02c3'
#p Wucluster::Snapshot.all

gibbon = Wucluster::Cluster.new(:gibbon)
gibbon.detach_volumes
gibbon.ensure_volumes_are_detached or raise "Couldn't detach all volumes"
gibbon.snapshot_volumes
gibbon.delete_old_snapshots
gibbon.delete_volumes_with_recent_snapshots
# puts gibbon.mounts.map(&:inspect)
# puts gibbon.snapshots.map(&:inspect)


# gibbon.mounts.each do |mount|
#   puts  mount.inspect
#
#   # puts "\t" + mount.volume.inspect
#   # mount.snapshots.each do |snapshot|
#   #   puts "\t\t" + snapshot.inspect
#   # end
# end

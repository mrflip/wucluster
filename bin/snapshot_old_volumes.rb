vols = []
require './bin/console_helper' ;
include Wucluster ;
gc = Cluster.new 'gibbon'

gc.send(:cluster_config )[:instances].each{|role, instances|
  instances.each_with_index{|inst_info, inst_idx|
    inst_info[:volumes].each_with_index{ |vol_info, mnt_idx|
      existing_vol = Volume.find(vol_info[:volume_id]) || {};
      vol = Volume.new(existing_vol.to_hash.merge({:cluster_name => gc.name, :cluster_node_id => role, :cluster_vol_id => "%03d"%inst_idx, :cluster_vol_index => "%03d"%mnt_idx, :mount_point => vol_info[:mount_point], :device => vol_info[:device] })) ;
      vols << vol }}} ; 1

vols.each{|vol| vol.snapshot! }

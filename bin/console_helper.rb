WUCLUSTER_DIR = File.dirname(__FILE__)+'/../lib/wucluster'
$: << WUCLUSTER_DIR + '/..'
require 'wucluster'
include Wucluster

def reload_wucluster!
  Dir["./lib/wucluster/**/*.rb"].each{|req| load req }
end

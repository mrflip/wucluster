module Wucluster
  def commandline_args
    ARGV
  end

  def commandline_has_flag flag
    ARGV.include?("--#{flag}")
  end
end

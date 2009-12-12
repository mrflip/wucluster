# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wucluster}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Philip (flip) Kromer"]
  s.date = %q{2009-12-12}
  s.description = %q{Persistent mapping of volume and snapshot to cluster, node and mount point}
  s.email = %q{flip@infochimps.org}
  s.extra_rdoc_files = [
    "LICENSE.textile",
     "README.textile"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE.textile",
     "README.textile",
     "Rakefile",
     "VERSION",
     "lib/wucluster.rb",
     "lib/wucluster/cluster.rb",
     "lib/wucluster/ec2_volume.rb",
     "spec/spec_helper.rb",
     "spec/wucluster_spec.rb"
  ]
  s.homepage = %q{http://github.com/mrflip/wucluster}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Simple EBS volume management for hadoop clusters}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/wucluster_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
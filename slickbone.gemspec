# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "slickbone/version"

Gem::Specification.new do |s|
  s.name        = "slickbone-rails"
  s.version     = Slickbone::VERSION
  s.authors     = ["Steve Whittaker"]
  s.email       = ["swhitt@gmail.com"]
  s.homepage    = "https://github.com/swhitt/slickbone-rails"
  s.summary     = %q{The slickest bone.}
  s.description = %q{Happy marry SlickGrid, Backbone.js and Rails}

  s.rubyforge_project = "slickbone-rails"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency 'rails', '>= 3.1.0.rc4'
  s.add_dependency 'coffee-script'
  s.add_development_dependency 'jquery-rails'
end

# -*- encoding: utf-8 -*-
# Copyright (c) 2009-2012 VMware, Inc.

Gem::Specification.new do |s|
  s.name         = "bootstrap-vmc-plugin"
  s.version      = '0.0.1'
  s.platform     = Gem::Platform::RUBY
  s.summary      = "VMC Bootstrap"
  s.description  = "VMC command line tool to bootstrap a CF deployment on top of BOSH"
  s.author       = "VMware"
  s.homepage      = 'https://github.com/cloudfoundry/bootstrap-vmc-plugin'
  s.license       = 'Apache 2.0'
  s.email         = "support@cloudfoundry.com"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  s.files        = `git ls-files -- lib/* templates/*`.split("\n") + %w(README.md)
  s.require_path = "lib"

  s.add_dependency "bosh_aws_bootstrap", "=1.5.0.pre2"
  s.add_dependency "vmc", "~>0.5"
end

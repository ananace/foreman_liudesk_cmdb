# frozen_string_literal: true

require_relative "lib/foreman_liudesk_cmdb/version"

Gem::Specification.new do |spec|
  spec.name        = "foreman_liudesk_cmdb"
  spec.version     = ForemanLiudeskCMDB::VERSION
  spec.authors     = ["Alexander Olofsson"]
  spec.email       = ["alexander.olofsson@liu.se"]

  spec.homepage    = "https://github.com/ananace/foreman_liudesk_cmdb"
  spec.summary     = "Integrate Foreman with the Linköping University CMDB"
  spec.description = spec.summary
  spec.license     = "GPL-3.0"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["{app,config,db,lib}/**/*.{rake,rb}"] + %w[LICENSE.txt README.md]

  spec.add_dependency "liudesk_cmdb"
end

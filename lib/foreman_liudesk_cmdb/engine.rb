# frozen_string_literal: true

require "deface"
require "interactor"
require "liudesk_cmdb"

# Preload CMDB models
# require "liudesk_cmdb/models/hardware"
# require "liudesk_cmdb/models/server"
# require "liudesk_cmdb/models/linux_client"
# require "liudesk_cmdb/models/linux_computerlab"
# require "liudesk_cmdb/models/windows_client"
# require "liudesk_cmdb/models/windows_computerlab"

module ForemanLiudeskCMDB
  # Plugin engine
  class Engine < ::Rails::Engine
    engine_name "foreman_liudesk_cmdb"

    config.autoload_paths += Dir["#{config.root}/app/interactors"]

    initializer "foreman_liudesk_cmdb.load_app_instance_data" do |app|
      ForemanLiudeskCMDB::Engine.paths["db/migrate"].existent.each do |path|
        app.config.paths["db/migrate"] << path
      end
    end

    initializer "foreman_liudesk_cmdb.register_plugin", before: :finisher_hook do |app|
      app.reloader.to_prepare do
        require_relative "register"
      end
    end

    # initializer 'foreman_liudesk_cmdb.require_dynflow', before: 'foreman_tasks.initialize_dynflow' do |_app|
    #   ForemanTasks.dynflow.require!
    #   ForemanTasks.dynflow.config.eager_load_paths << File.join(ForemanLiudeskCMDB::Engine.root, 'app/lib/actions')
    # end

    config.to_prepare do
      Nic::Base.include ForemanLiudeskCMDB::NicBaseExtensions
      HostFactImporter.prepend ForemanLiudeskCMDB::HostFactImporterExtensions
    rescue StandardError => e
      Rails.logger.warn "foreman_liudesk_cmdb: skipping engine hook (#{e})\n#{e.backtrace.join("\n")}"
    end
  end
end

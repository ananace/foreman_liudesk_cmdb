# frozen_string_literal: true

module ForemanLiudeskCMDB
  class Engine < ::Rails::Engine
    engine_name "foreman_liudesk_cmdb"

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    # config.autoload_paths += Dir["#{config.root}/app/services"]

    initializer "foreman_liudesk_cmdb.load_app_instance_data" do |app|
      ForemanLiudeskCMDB::Engine.paths["db/migrate"].existent.each do |path|
        app.config.paths["db/migrate"] << path
      end
    end

    initializer "foreman_liudesk_cmdb.register_plugin", before: :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_liudesk_cmdb do
        requires_foreman ">= 3.0"

        register_facet ForemanLiudeskCMDB::LiudeskCMDBFacet, :liudesk_cmdb_facet do
          configure_host do
            set_dependent_action :destroy

            extend_model ForemanLiudeskCMDB::HostExtensions
            # add_tabs liudesk_cmdb_facet: "foreman_liudesk/liudesk_cmdb_facet"
          end

          configure_hostgroup ForemanLiudeskCMDB::LiudeskCMDBHostgroupFacet do
            set_dependent_action :destroy
          end
        end
      end
    end

    config.to_prepare do
      # XXX
    rescue StandardError => e
      Rails.logger.fatal "foreman_liudesk_cmdb: skipping engine hook (#{e})"
    end
  end
end

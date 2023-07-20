# frozen_string_literal: true

module ForemanLiudeskCMDB
  # Plugin engine
  class Engine < ::Rails::Engine
    engine_name "foreman_liudesk_cmdb"

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/interactors"]
    # config.autoload_paths += Dir["#{config.root}/app/services"]

    initializer "foreman_liudesk_cmdb.load_app_instance_data" do |app|
      ForemanLiudeskCMDB::Engine.paths["db/migrate"].existent.each do |path|
        app.config.paths["db/migrate"] << path
      end
    end

    # rubocop:disable Metrics/BlockLength
    initializer "foreman_liudesk_cmdb.register_plugin", before: :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_liudesk_cmdb do
        requires_foreman ">= 3.7"

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

        settings do
          category(:liudesk_cmdb, N_("CMDB")) do
            setting "liudesk_cmdb_url",
                    type: :string,
                    default: "https://api.test.liu.se",
                    full_name: N_("CMDB API URL"),
                    description: N_("URL where the CMDB API is located")
            setting :liudesk_cmdb_token,
                    type: :string,
                    default: "-",
                    full_name: N_("CMDB API Token"),
                    description: N_("Access token for the CMDB API")
            setting :liudesk_cmdb_orchestration_enabled,
                    type: :boolean,
                    default: false,
                    full_name: N_("CMDB Orchestration"),
                    description: N_("Enable CMDB Orchestration")
          end
        end

        logger :sync, enabled: true
      end
    end
    # rubocop:enable Metrics/BlockLength

    config.to_prepare do
      # XXX
    rescue StandardError => e
      Rails.logger.warn "foreman_liudesk_cmdb: skipping engine hook (#{e})\n#{e.backtrace.join("\n")}"
    end
  end
end

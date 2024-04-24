# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a hardware object to the context is one is available
      class Create
        include ::Interactor

        around do |interactor|
          interactor.call unless context.hardware
        end

        def call
          context.hardware = ForemanLiudeskCMDB::API.create_asset(:hardware_v1, **params.merge(ephemeral_params))
        rescue LiudeskCMDB::UnprocessableError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .warn("#{self.class} error #{e}, attempting with only primary interface")

          cleaned_params = cmdb_params[:hardware]
          primary = context.host.primary_interface
          cleaned_params[:mac_and_network_access_roles] = [
            {
              mac: primary.mac,
              networkAccessRole: primary.deep_network_access_role || "None"
            }
          ]

          context.hardware = ForemanLiudeskCMDB::API.create_asset(:hardware_v1, **cleaned_params)
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error_obj: e, error: "#{self.class}: #{e}")
        end

        private

        delegate :cmdb_params, to: :context
        delegate :host, to: :context

        def facet
          host.liudesk_cmdb_facet
        end

        def params
          cmdb_params[:hardware]
        end

        def ephemeral_params
          facet.ephemeral_attributes[:hardware]
        end
      end
    end
  end
end

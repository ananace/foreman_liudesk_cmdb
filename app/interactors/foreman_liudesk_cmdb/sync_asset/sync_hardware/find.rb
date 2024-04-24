# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a hardware object to the context is one is available
      class Find
        include ::Interactor

        around do |interactor|
          interactor.call if search_params.any? && !context.hardware
        end

        def call
          found = ForemanLiudeskCMDB::API.find_asset(facet.hardware_model_type, **search_params)

          if found.count > 1
            ::Foreman::Logging
              .logger("foreman_liudesk_cmdb/sync")
              .warn("#{self.class} found multiple potential hardware assets.")
          end

          context.hardware = found.first
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error_obj: e, error: "#{self.class}: #{e}")
        end

        private

        delegate :cmdb_params, :host, to: :context

        def facet
          host.liudesk_cmdb_facet
        end

        def search_params
          cmdb_params[:hardware]
            .slice(:bios_uuid, :serial_number)
            .merge("macAndNetworkAccessRoles.mac": host.mac&.upcase)
            .reject { |_, v| v.nil? || v.empty? }
        end
      end
    end
  end
end

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
          context.hardware = ForemanLiudeskCMDB::API.find_asset(:hardware_v1, **search_params).first
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error: "#{self.class}: #{e}")
        end

        private

        delegate :cmdb_params, to: :context

        def search_params
          cmdb_params[:hardware].slice(:bios_uuid, :serial_number)
          # .merge(mac: cmdb_params.dig(:hardware, :mac_and_network_access_roles).map { |nmap| nmap[:mac] })
        end
      end
    end
  end
end

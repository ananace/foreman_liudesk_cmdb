# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a hardware object to the context is one is available
      class Find
        include ::Interactor

        around do |interactor|
          interactor.call unless context.hardware
        end

        def call
          context.hardware = ForemanLiudeskCMDB::API.find_asset(:hardware_v1, **search_params).first
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error: "#{self.class}: #{e}")
        end

        private

        delegate :host, to: :context

        def search_params
          {
            serial_number: host.facts["dmi::product::serial_number"] || host.facts["serialnumber"],
            bios_uuid: host.facts["dmi::product::uuid"] || host.facts["uuid"]
          }.compact
        end
      end
    end
  end
end

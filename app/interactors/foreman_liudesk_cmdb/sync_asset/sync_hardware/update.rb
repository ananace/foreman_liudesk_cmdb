# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Attaches a hardware object to the context is one is available
      class Create
        include ::Interactor

        around do |interactor|
          interactor.call if context.hardware
        end

        def update_params
          %i[serial_number bios_uuid]
        end

        def call
          hardware_params.slice(*update_params).each do |key, value|
            hardware.send("#{key}=".to_sym, value) if cached_hardware_params[key] != value
          end

          hardware.patch! if hardware.changed?
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")
          context.fail!(error: "#{self.class}: #{e}")
        end

        private

        delegate :cached_params, :cmdb_params, :hardware, to: :context

        def cached_hardware_params
          cached_params[:hardware]
        end

        def hardware_params
          cmdb_params[:hardware]
        end
      end
    end
  end
end

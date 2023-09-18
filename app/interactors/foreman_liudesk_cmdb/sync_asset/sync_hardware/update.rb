# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Applies any pending changes to the asset hardware object
      class Update
        include ::Interactor

        around do |interactor|
          interactor.call if context.hardware
        end

        def update_params
          %i[serial_number bios_uuid mac_and_network_access_roles]
        end

        def call
          hardware_params.slice(*update_params).each do |key, value|
            if hardware.retrieved?
              hardware.send(:"#{key}=", value) unless value_diff?(key, hardware.send(key), value)
            elsif value_diff?(key, cached_hardware_params[key], value)
              hardware.send(:"#{key}=", value)
            end
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

        def value_diff?(key, current, wanted)
          if key == :mac_and_network_access_roles
            current.to_h { |val| [(val[:mac] || val["mac"]).downcase, val[:networkAccessRole] || val["networkAccessRole"]] } \
              != wanted.to_h { |val| [(val[:mac] || val["mac"]).downcase, val[:networkAccessRole] || val["networkAccessRole"]] }
          else
            current != wanted
          end
        end
      end
    end
  end
end

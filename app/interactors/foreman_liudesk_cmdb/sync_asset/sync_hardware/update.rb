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
          %i[make model serial_number bios_uuid mac_and_network_access_roles]
        end

        def call
          hardware_params.slice(*update_params).merge(ephemeral_params).each do |key, value|
            if hardware.retrieved?
              hardware.send(:"#{key}=", value) unless value_diff?(key, hardware.send(key), value)
            elsif value_diff?(key, cached_hardware_params[key], value)
              hardware.send(:"#{key}=", value)
            end
          end

          hardware.patch! if hardware.changed?
        rescue LiudeskCMDB::NotFoundError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}, resetting asset id")

          facet.update hardware_id: nil

          context.fail!(error_obj: e, error: "#{self.class}: #{e}")
        rescue StandardError => e
          ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                            .error("#{self.class} error #{e}: #{e.backtrace}")

          context.error_obj = e
          context.error = "#{self.class}: #{e}"
          context.fail! unless e.to_s =~ /mac is already assigned/i
        end

        private

        delegate :cached_params, :cmdb_params, :hardware, :host, to: :context

        def facet
          host.liudesk_cmdb_facet
        end

        def cached_hardware_params
          cached_params[:hardware]
        end

        def hardware_params
          cmdb_params[:hardware]
        end

        def ephemeral_params
          context.host.liudesk_cmdb_facet.ephemeral_attributes[:hardware]
        end

        def value_diff?(key, current, wanted)
          if key == :mac_and_network_access_roles
            cleanup = proc do |val|
              indifferent = val.with_indifferent_access
              OpenStruct.new(mac: indifferent[:mac]&.downcase, role: indifferent[:networkAccessRole]) # rubocop:disable Style/OpenStructUse
            end
            current_mac = current.map(&cleanup).select(&:mac).sort_by(&:mac) if current
            wanted_mac = wanted.map(&cleanup).select(&:mac).sort_by(&:mac) if wanted

            current_mac != wanted_mac
          else
            current != wanted
          end
        end
      end
    end
  end
end

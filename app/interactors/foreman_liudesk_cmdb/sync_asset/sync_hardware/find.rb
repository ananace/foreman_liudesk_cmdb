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
          found = ForemanLiudeskCMDB::Api.find_asset(facet.hardware_model_type, **search_params).sort_by do |hw|
            evaluate_correctness(hw, search_params)
          end

          if search_params[:bios_uuid]
            found.reject! { |hw| hw.bios_uuid && hw.bios_uuid.downcase != search_params[:bios_uuid].downcase }
          end

          if found.count > 1
            ::Foreman::Logging
              .logger("foreman_liudesk_cmdb/sync")
              .warn("#{self.class} found multiple potential hardware assets for #{search_params}")
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

        def evaluate_correctness(hardware, search_params)
          divergence = 0
          if search_params[:bios_uuid]
            divergence += 9000 if hardware.bios_uuid&.downcase != search_params[:bios_uuid].downcase
          elsif hardware.bios_uuid.nil? || hardware.bios_uuid.empty?
            divergence += 0.5
          end
          if search_params[:serial_number]
            divergence += 50 if hardware.serial_number&.downcase != search_params[:serial_number].downcase
          elsif hardware.serial_number.nil? || hardware.serial_number.empty?
            divergence += 0.5
          end
          if search_params['macAndNetworkAccessRoles.mac']
            divergence += 2 unless hardware.mac_and_network_access_roles
                                          &.any? { |nic| nic[:mac].downcase == search_params['macAndNetworkAccessRoles.mac'].downcase }
          end
          divergence += 1 if hardware.hostname && hardware.hostname.downcase != host.name.downcase
          divergence
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

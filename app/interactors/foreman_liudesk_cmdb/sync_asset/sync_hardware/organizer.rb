# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Organizes the syncing of a CMDB hardware asset
      class Organizer
        include ::Interactor::Organizer

        def call
          super
        ensure
          if context.hardware&.retrieved?
            context.raw_data[:hardware] = context.hardware.class.convert_ruby_to_cmdb context.hardware.raw_data!
            context.raw_data[:hardware_type] = context.hardware.class.name.split("::").last._cmdb_snake_case
          end
        end

        organize SyncHardware::FindThin,
                 SyncHardware::Find,
                 SyncHardware::Update,
                 SyncHardware::Create,
                 SyncHardware::UpdateFacet
      end
    end
  end
end

# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    module SyncHardware
      # Organizes the syncing of a CMDB hardware asset
      class Organizer
        include ::Interactor::Organizer

        after do
          context.raw_data[:hardware] = context.hardware.raw_data! if context.hardware.retrieved?
        end

        organize SyncHardware::FindThin,
                 SyncHardware::Find,
                 SyncHardware::Create,
                 SyncHardware::Update
      end
    end
  end
end

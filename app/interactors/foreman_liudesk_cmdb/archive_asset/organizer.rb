# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Organizes the archiving of removed CMDB assets - along with their hardware if virtual
    class Organizer
      include ::Interactor::Organizer

      organize ForemanLiudeskCMDB::ArchiveAsset::AttachThinAsset,
               ForemanLiudeskCMDB::ArchiveAsset::AttachThinHardware,
               ForemanLiudeskCMDB::ArchiveAsset::ArchiveAsset,
               ForemanLiudeskCMDB::ArchiveAsset::ArchiveHardware
    end
  end
end

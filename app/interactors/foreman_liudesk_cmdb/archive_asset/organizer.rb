# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Organizes the archiving of removed CMDB assets - along with their hardware if virtual
    class Organizer
      include ::Interactor::Organizer

      organize ArchiveAsset::FindThinAsset,
               ArchiveAsset::FindThinHardware,
               ArchiveAsset::ArchiveAsset,
               ArchiveAsset::ArchiveHardware
    end
  end
end

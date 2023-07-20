# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Attaches a CMDB hardware asset to the context is one is available
    class FindThinHardware
      include ::Interactor

      around do |interactor|
        interactor.call if facet&.hardware_id
      end

      def call
        context.hardware = ForemanLiudeskCMDB::API.get_asset(:hardware_v1, facet.hardware_id, thin: true)
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end

      private

      def facet
        context.host.liudesk_cmdb_facet
      end
    end
  end
end

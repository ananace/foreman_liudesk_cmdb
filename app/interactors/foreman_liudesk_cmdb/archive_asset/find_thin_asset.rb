# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Attaches a CMDB asset to the context if one is available
    class FindThinAsset
      include ::Interactor

      around do |interactor|
        interactor.call if facet&.asset_id
      end

      def call
        context.asset = ForemanLiudeskCMDB::API.get_asset(facet.asset_type, facet.asset_id, thin: true)
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

# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Attaches a thin asset object to the context is one is available
    class AttachThin
      include ::Interactor

      around do |interactor|
        interactor.call if facet.asset?
      end

      def call
        context.asset = ForemanLiudeskCMDB::API.get_asset asset_model_type, facet.asset_id, thin: thin?
      rescue LiudeskCMDB::NotFoundError
        # Asset likely removed externally, mark for re-discovery/creation
        facet.update asset_id: nil if facet.asset_id
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end

      private

      delegate :host, to: :context

      def facet
        host.liudesk_cmdb_facet
      end

      def asset_model_type
        facet.cached_asset_parameters[:asset_type] || facet.asset_model_type
      end

      def thin?
        (Time.now - (facet.sync_at || Time.now)) < ForemanLiudeskCMDB::LiudeskCMDBFacet::FULL_RESYNC_INTERVAL
      end
    end
  end
end

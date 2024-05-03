# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Attaches a thin asset object to the context is one is available
    class Attach
      include ::Interactor

      around do |interactor|
        interactor.call if facet.asset?
      end

      def call
        context.asset = ForemanLiudeskCMDB::API.get_asset asset_model_type, facet.asset_id
      rescue LiudeskCMDB::NotFoundError
        # Asset likely removed externally, mark for re-discovery/creation
        facet.update asset_id: nil
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error_obj: e, error: "#{self.class}: #{e}")
      end

      private

      delegate :host, to: :context

      def facet
        host.liudesk_cmdb_facet
      end

      def asset_model_type
        facet.cached_asset_parameters[:asset_type] || facet.asset_model_type
      end
    end
  end
end

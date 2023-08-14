# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Attaches a thin asset object to the context is one is available
    class Find
      include ::Interactor

      around do |interactor|
        interactor.call if facet.asset_id
      end

      def call
        context.asset = ForemanLiudeskCMDB::API.get_asset(asset_model_type, facet.asset_id, thin: true)
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
    end
  end
end

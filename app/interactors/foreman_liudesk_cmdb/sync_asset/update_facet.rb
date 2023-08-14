# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Applies any pending asset id changes to the facet
    class UpdateFacet
      include ::Interactor

      around do |interactor|
        interactor.call if asset && asset.identifier != facet.asset_id
      end

      def call
        facet.update asset_id: asset.identifier
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end

      private

      delegate :host, :asset, to: :context

      def facet
        host.liudesk_cmdb_facet
      end
    end
  end
end

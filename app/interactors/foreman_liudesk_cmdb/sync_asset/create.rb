# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Creates and attaches an asset object to the context is one is available
    class Create
      include ::Interactor

      around do |interactor|
        interactor.call if facet.hardware_id && !facet.asset_id
      end

      def call
        context.asset = ForemanLiudeskCMDB::API.create_asset(facet.asset_model_type, **params)
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

      def params
        context.cmdb_params[:asset].merge(hardware_id: facet.hardware_id)
      end
    end
  end
end

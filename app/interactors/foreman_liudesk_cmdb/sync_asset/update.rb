# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Applies any pending changes to the existing asset object
    class Update
      include ::Interactor

      around do |interactor|
        interactor.call if context.asset
      end

      def call
        asset_params.slice(*update_params).each do |key, value|
          asset.send("#{key}=".to_sym, value) if asset_hardware_params[key] != value
        end

        asset.patch! if asset.changed?
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end

      private

      delegate :cached_params, :cmdb_params, :asset, to: :context

      def update_params
        params = context.host.liudesk_cmdb_facet.asset_parameter_keys
        params.delete(:network_access_role)
        params
      end

      def cached_asset_params
        cached_params[:asset]
      end

      def asset_params
        cmdb_params[:asset]
      end
    end
  end
end

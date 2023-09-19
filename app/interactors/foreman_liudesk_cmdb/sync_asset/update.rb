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
          if asset.retrieved?
            asset.send(:"#{key}=", value) unless value_diff?(key, asset.send(key), value)
          elsif value_diff?(key, cached_asset_params[key], value)
            asset.send(:"#{key}=", value)
          end
        end

        # Always push all NAC keys if any is changed, to work around CMDB API issues
        nac_keys = %i[network_access_role certificate_information network_certificate_ca]
        if nac_keys.any? { |key| asset.changed?(key) } && nac_keys.all? { |key| asset.respond_to?(key) }
          nac_keys.each do |key|
            asset.instance_variable_get(:@old_data).delete key
            asset.send :"#{key}=", asset_params[key]
          end
        end

        asset.patch! if asset.changed?
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end

      private

      delegate :cached_params, :cmdb_params, :asset, :host, to: :context

      def facet
        host.liudesk_cmdb_facet
      end

      def update_params
        params = facet.asset_parameter_keys
        params.delete :network_access_role if facet.network_role.nil? || facet.network_role.empty?

        params
      end

      def cached_asset_params
        cached_params[:asset]
      end

      def asset_params
        cmdb_params[:asset]
      end

      def value_diff?(_key, current, wanted)
        current != wanted
      end
    end
  end
end

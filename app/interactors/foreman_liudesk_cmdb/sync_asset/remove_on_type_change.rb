# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Removes the CMDB asset if the type has changed - e.g. server_v1 -> linux/windows_client_v1
    class RemoveOnTypeChange
      include ::Interactor

      around do |interactor|
        interactor.call if old_asset_type &&
                           context.asset &&
                           old_asset_type != facet.asset_model_type
      end

      def call
        # Rename before deprecation to avoid collision
        # FIXME: This is temporary until deprecation supports name reuse
        context.asset.identifier += "-chng-#{Time.now.to_i}"
        context.asset.patch!

        context.asset.delete!
        context.asset = nil
        facet.asset_id = nil
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

      def old_asset_type
        facet.cached_asset_parameters[:asset_type]
      end
    end
  end
end

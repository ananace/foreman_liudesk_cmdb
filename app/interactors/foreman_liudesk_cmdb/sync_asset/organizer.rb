# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Organizes the creation/update of a CMDB asset and its associated hardware
    class Organizer
      include ::Interactor::Organizer

      before do
        context.cached_params = facet.cached_asset_parameters
        context.cmdb_params = facet.asset_parameters
        context.raw_data = {}
      end

      after do
        context.raw_data[:asset] = context.asset.raw_data! if context.asset.retrieved?
      end

      organize SyncAsset::SyncHardware::Organizer,
               SyncAsset::FindThin,
               SyncAsset::Find,
               SyncAsset::RemoveOnTypeChange,
               SyncAsset::Create,
               SyncAsset::Update

      def call
        super
      ensure
        update_status
      end

      private

      delegate :host, :error, to: :context

      def facet
        host.liudesk_cmdb_facet
      end

      def update_status
        facet.update(sync_at: Time.zone.now, sync_error: error, raw_data: context.raw_data)
      end
    end
  end
end

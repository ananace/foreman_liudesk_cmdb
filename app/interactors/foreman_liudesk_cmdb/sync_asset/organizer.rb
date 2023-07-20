# frozen_string_literal: true

module ForemanLiudeskCMDB
  module SyncAsset
    # Organizes the creation/update of a CMDB asset and its associated hardware
    class Organizer
      include ::Interactor::Organizer

      before do
        context.raw_data = {}
      end

      organize SyncAsset::SyncHardware::Organizer,
               SyncAsset::Validate,
               SyncAsset::FindThin,
               SyncAsset::Find,
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

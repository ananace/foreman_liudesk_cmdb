# frozen_string_literal: true

module ForemanLiudeskCMDB
  module ArchiveAsset
    # Archives the CMDB asset
    class ArchiveAsset
      include ::Interactor

      around do |interactor|
        interactor.call if context.asset
      end

      def call
        # Rename before deprecation to avoid collision
        # FIXME: This is temporary until deprecation supports name reuse
        context.asset.identifier += "-depr-#{Time.now.to_i}"
        context.asset.patch!

        context.asset.delete!
      rescue StandardError => e
        ::Foreman::Logging.logger("foreman_liudesk_cmdb/sync")
                          .error("#{self.class} error #{e}: #{e.backtrace}")
        context.fail!(error: "#{self.class}: #{e}")
      end
    end
  end
end

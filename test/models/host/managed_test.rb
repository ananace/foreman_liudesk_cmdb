# frozen_string_literal: true

require "test_plugin_helper"

module Host
  class ManagedTest < ActiveSupport::TestCase
    let(:host) { FactoryBot.build(:host, :managed, :with_liudesk_cmdb_facet) }

    context "a host with CMDB orchestration" do
      setup do
        disable_orchestration
        setup_default_cmdb_settings
      end

      test "should post_queue CMDB sync" do
        host.save
        tasks = host.post_queue.all.map(&:name)
        assert_includes tasks, "Sync CMDB asset for host #{host}"
        assert_equal 1, tasks.size
      end

      test "should destroy CMDB data" do
        assert_valid host
        host.queue.clear

        ForemanLiudeskCMDB::ArchiveAsset::Organizer.expects(:call).with(host: host)

        host.destroy
      end
    end
  end
end

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

      it "should post_queue CMDB sync" do
        host.save
        tasks = host.post_queue.all.map(&:name)
        assert_includes tasks, "Sync CMDB asset for host #{host}"
        assert_equal 1, tasks.size
      end

      it "should destroy CMDB data" do
        assert_valid host
        host.queue.clear

        ForemanLiudeskCMDB::ArchiveAsset::Organizer.expects(:call).with(host: host)

        host.destroy
      end

      it "should retrieve asset when requested" do
        host.liudesk_cmdb_facet.asset_type = "server"
        host.liudesk_cmdb_facet.asset_id = host.name

        stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/#{host.name}").to_return(
          status: 200,
          body: {
            hostName: host.name,
            hardwareID: "blah"
          }.to_json
        )

        asset = host.liudesk_cmdb_facet.asset

        assert_equal host.name, asset.identifier
        assert_equal "blah", asset.hardware_id
        assert_requested stub_get
      end

      it "should retrieve hardware when requested" do
        host.liudesk_cmdb_facet.hardware_id = "something"

        stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/something").to_return(
          status: 200,
          body: {
            guid: "something"
          }.to_json
        )

        hardware = host.liudesk_cmdb_facet.hardware

        assert_equal "something", hardware.identifier
        assert_requested stub_get
      end

      it "should support launching an archive asset job" do
        assert_valid host
        host.queue.clear

        ForemanLiudeskCMDB::ArchiveAssetJob.expects(:perform_later).with(host.id)

        host.send :cmdb_archive_asset
      end

      it "should not fail deletion despite CMDB errors" do
        assert_valid host
        host.queue.clear

        host.liudesk_cmdb_facet.asset_type = "server"
        host.liudesk_cmdb_facet.asset_id = host.fqdn
        assert host.send :cmdb_orchestration?

        Time.stubs(:now).returns(Time.new(2020, 1, 1))
        stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/#{host.fqdn}").with(
          body: {
            hostName: "#{host.fqdn}-depr-#{Time.now.to_i}"
          }
        ).to_return(
          status: 400,
          body: {}.to_json
        )
        stub_delete = stub_request(:delete, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/#{host.fqdn}")

        host.destroy

        assert_requested stub_patch
        refute_requested stub_delete
      end

      it "should handle updating attributes" do
        refute_equal "Guest", host.liudesk_cmdb_facet.network_role

        host.liudesk_cmdb_facet! network_role: "Guest"

        assert_equal "Guest", host.liudesk_cmdb_facet.network_role
      end
    end

    context "a host in a hostgroup with CMDB orchestration" do
      let(:hostgroup) { FactoryBot.build(:hostgroup, :with_liudesk_cmdb_facet) }
      let(:host) { FactoryBot.build(:host, :managed) }

      it "should inherit CMDB configuration" do
        host.hostgroup = hostgroup

        refute host.liudesk_cmdb_facet
        assert hostgroup.liudesk_cmdb_facet

        h_facet = host.liudesk_cmdb_facet!
        hg_facet = hostgroup.liudesk_cmdb_facet

        assert h_facet
        assert_equal hg_facet.asset_type, h_facet.asset_type
      end
    end

    context "a host without CMDB orchestration" do
      let(:host) { FactoryBot.build(:host, :managed) }

      it "should not post_queue CMDB sync" do
        refute host.liudesk_cmdb_facet
        host.save
        tasks = host.post_queue.all.map(&:name)
        refute_includes tasks, "Sync CMDB asset for host #{host}"
        assert tasks.empty?
      end

      it "should not destroy CMDB data" do
        refute host.liudesk_cmdb_facet
        assert_valid host
        host.queue.clear

        ForemanLiudeskCMDB::ArchiveAsset::Organizer.expects(:call).never

        host.destroy
      end
    end
  end
end

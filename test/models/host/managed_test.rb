# frozen_string_literal: true

require "test_plugin_helper"

module Host
  class ManagedTest < ActiveSupport::TestCase
    include FactImporterIsolation
    allow_transactions_for_any_importer

    setup do
      disable_orchestration
      setup_default_cmdb_settings
    end

    let(:host) { FactoryBot.build(:host, :managed, :with_liudesk_cmdb_facet) }

    context "a host with CMDB orchestration" do
      it "should post_queue CMDB sync" do
        host.save
        tasks = host.post_queue.all.map(&:name)
        assert_includes tasks, "Sync CMDB asset for host #{host}"
        assert_equal 1, tasks.size
      end

      it "should destroy CMDB data" do
        assert_valid host
        host.queue.clear

        ForemanLiudeskCMDB::ArchiveAsset::Organizer.expects(:call!).with(host: host)

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
            hostName: "d-#{Time.now.to_i.to_s(36)}-#{host.fqdn}"
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

      it "should handle network access roles for its interfaces" do
        refute host.primary_interface.network_access_role

        host.primary_interface.network_access_role = "Guest"

        assert_equal(
          {
            host.primary_interface.mac => {
              "role" => "Guest"
            }
          },
          host.liudesk_cmdb_facet.hardware_network_roles
        )
      end

      it "should push asset updates when facts cause changes in asset" do
        host.liudesk_cmdb_facet.raw_data = host.liudesk_cmdb_facet.asset_parameters

        host.expects(:cmdb_sync_asset)

        HostFactImporter.new(host).import_facts(
          os: {
            family: "RedHat",
            hardware: "x86_64",
            name: "RedHat",
            release: {
              full: "8.8",
              major: 8,
              minor: 8
            }
          }
        )

        assert host.liudesk_cmdb_facet.asset_will_change?
        assert host.cmdb_orchestration_with_inherit?
      end

      it "should not push asset when facts don't cause changes in asset" do
        host.id = 999
        host.liudesk_cmdb_facet.raw_data = host.liudesk_cmdb_facet.asset_parameters

        host.stubs(:cmdb_sync_asset)

        HostFactImporter.new(host).import_facts(
          os: {
            family: host.operatingsystem.family,
            name: host.operatingsystem.name,
            release: {
              major: host.operatingsystem.major,
              minor: host.operatingsystem.minor
            }
          },
          environment: "devel",
          is_virtual: true,
          memory: {
            system: {
              total_bytes: 1024
            }
          },
          processors: {
            physicalcount: 2,
            count: 96
          },
          dmi: {
            bios: {
              vendor: "example",
              version: "1.0",
              release_date: Time.now.strftime("%Y-%m-%d")
            }
          }
        )

        refute host.liudesk_cmdb_facet.asset_will_change?
        refute host.cmdb_orchestration_with_inherit?
      end

      it "should consider ephemeral attributes to be changes in addition to fact-based changes" do
        host.liudesk_cmdb_facet.raw_data = host.liudesk_cmdb_facet.asset_parameters
        host.liudesk_cmdb_facet.asset_type = :server
        host.liudesk_cmdb_facet.clear_changes_information

        assert_equal({}, host.liudesk_cmdb_facet.asset_params_diff)
        refute host.liudesk_cmdb_facet.asset_will_change?

        host.liudesk_cmdb_facet.ephemeral_attributes = { asset: { misc_information: "Testing" } }

        assert_equal({ asset: { misc_information: "Testing" } }, host.liudesk_cmdb_facet.asset_params_diff)
        assert host.liudesk_cmdb_facet.asset_will_change?

        host.stubs(:save)
        host.expects(:cmdb_sync_asset)
        HostFactImporter.new(host).import_facts(
          os: {
            family: "RedHat",
            hardware: "x86_64",
            name: "RedHat",
            release: {
              full: "8.8",
              major: 8,
              minor: 8
            }
          }
        )

        assert_equal(
          { asset: { operating_system_type: "RedHat", operating_system: "RedHat 8.8", misc_information: "Testing" } },
          host.liudesk_cmdb_facet.asset_params_diff
        )
        assert host.liudesk_cmdb_facet.asset_will_change?
        assert host.cmdb_orchestration_with_inherit?
      end
    end

    context "a host in a hostgroup with CMDB orchestration" do
      let(:hostgroup) do
        FactoryBot.build(:hostgroup, :with_liudesk_cmdb_facet).tap do |hostgroup|
          hostgroup.liudesk_cmdb_facet.asset_type = :server
        end
      end
      let(:host) do
        FactoryBot.build(:host, :managed).tap do |host|
          host.hostgroup = hostgroup
        end
      end

      before(:each) do
        refute host.liudesk_cmdb_facet
        assert hostgroup.liudesk_cmdb_facet
      end

      it "should inherit CMDB configuration" do
        h_facet = host.liudesk_cmdb_facet!
        hg_facet = hostgroup.liudesk_cmdb_facet

        assert h_facet
        assert_equal hg_facet.asset_type, h_facet.asset_type
      end

      it "should push asset on fact upload, regardless of fact data" do
        assert host.cmdb_orchestration_with_inherit?

        host.expects(:cmdb_sync_asset)

        HostFactImporter.new(host).import_facts(
          os: {
            family: "RedHat",
            hardware: "x86_64",
            name: "RedHat",
            release: {
              full: "8.8",
              major: 8,
              minor: 8
            }
          },
          environment: "devel",
          is_virtual: true,
          memory: {
            system: {
              total_bytes: 1024
            }
          },
          processors: {
            physicalcount: 2,
            count: 96
          },
          dmi: {
            bios: {
              vendor: "example",
              version: "1.0",
              release_date: Time.now.strftime("%Y-%m-%d")
            }
          }
        )
      end
    end

    context "a host without CMDB orchestration" do
      let(:hostgroup) { FactoryBot.build(:hostgroup) }
      let(:host) do
        FactoryBot.build(:host, :managed).tap do |host|
          host.hostgroup = hostgroup
        end
      end

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

      it "should not sync asset on fact uploads" do
        refute host.cmdb_orchestration_with_inherit?

        host.expects(:cmdb_sync_asset).never

        HostFactImporter.new(host).import_facts(
          os: {
            family: "RedHat",
            hardware: "x86_64",
            name: "RedHat",
            release: {
              full: "8.8",
              major: 8,
              minor: 8
            }
          }
        )
      end
    end
  end
end

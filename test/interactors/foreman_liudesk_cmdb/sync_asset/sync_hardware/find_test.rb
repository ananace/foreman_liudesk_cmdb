# frozen_string_literal: true

require "test_plugin_helper"

class FindHardwareTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::SyncHardware::Find.call(
      host: host,
      hardware: hardware,
      cmdb_params: host.liudesk_cmdb_facet.asset_parameters
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
  let(:hardware_id) { nil }
  let(:hardware) { nil }
  let(:mac) { "00:01:02:03:04:05" }
  let(:host) do
    FactoryBot.build_stubbed(:host, hostname: hostname).tap do |host|
      host.stubs(:facts).returns(
        "serialnumber" => "abc123",
        "manufacturer" => "HP",
        "productname" => "HP ProLiant DL480 Gen8",
        "uuid" => "515bd9a2-d42a-4d4a-b57d-6ce464b549b8"
      )
      host.primary_interface.mac = mac

      facet = host.build_liudesk_cmdb_facet
      facet.asset_type = asset_type
      facet.network_role = network_role
      facet.hardware_id = hardware_id
      facet.asset_id = asset_id
    end
  end

  setup do
    setup_default_cmdb_settings
  end

  context "when hardware is not assigned" do
    it "searches for a hardware object and attaches if found" do
      stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/search").with(
        query: { query: "biosUuid==515bd9a2-d42a-4d4a-b57d-6ce464b549b8,serialNumber==abc123,macAndNetworkAccessRoles.mac==00:01:02:03:04:05" }
      ).to_return(
        status: 200,
        body: [
          {
            guid: "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0",
            make: "HP",
            model: "ProLiant DL480 Gen8",
            name: "HP Proliant DL480 Gen8-0001"
          }
        ].to_json
      )

      assert subject.success?
      assert subject.hardware
      assert_equal "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0", subject.hardware.identifier
      assert_requested stub_get
    end

    it "handles multiple results" do
      stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/search").with(
        query: { query: "biosUuid==515bd9a2-d42a-4d4a-b57d-6ce464b549b8,serialNumber==abc123,macAndNetworkAccessRoles.mac==00:01:02:03:04:05" }
      ).to_return(
        status: 200,
        body: [
          {
            guid: "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0",
            make: "HP",
            model: "ProLiant DL480 Gen8",
            name: "HP Proliant DL480 Gen8-0001"
          },
          {
            guid: "48fd8d16-be97-4e79-b1c6-46b831fffad9",
            make: "HP",
            model: "ProLiant DL480 Gen8",
            name: "HP Proliant DL480 Gen8-0002"
          }
        ].to_json
      )

      assert subject.success?
      assert subject.hardware
      assert_equal "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0", subject.hardware.identifier
      assert_requested stub_get
    end

    it "searches for a hardware object and handles empty result correctly" do
      stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/search").with(
        query: { query: "biosUuid==515bd9a2-d42a-4d4a-b57d-6ce464b549b8,serialNumber==abc123,macAndNetworkAccessRoles.mac==00:01:02:03:04:05" }
      ).to_return(
        status: 200,
        body: [].to_json
      )

      assert subject.success?
      refute subject.hardware
      assert_requested stub_get
    end

    it "handles errors correctly" do
      stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/search").with(
        query: { query: "biosUuid==515bd9a2-d42a-4d4a-b57d-6ce464b549b8,serialNumber==abc123,macAndNetworkAccessRoles.mac==00:01:02:03:04:05" }
      ).to_return(
        status: 400,
        body: {}.to_json
      )

      refute subject.success?
      refute subject.hardware
      assert_requested stub_get
    end

    context "when host lacks a MAC-address" do
      let(:mac) { "" }


      it "generates a valid search string" do
        stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/search").with(
          query: { query: "biosUuid==515bd9a2-d42a-4d4a-b57d-6ce464b549b8,serialNumber==abc123" }
        ).to_return(
          status: 200,
          body: [
            {
              guid: "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0",
              make: "HP",
              model: "ProLiant DL480 Gen8",
              name: "HP Proliant DL480 Gen8-0001"
            }
          ].to_json
        )

        assert subject.success?
        assert subject.hardware
        assert_equal "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0", subject.hardware.identifier
        assert_requested stub_get
      end
    end
  end

  context "when hardware is already assigned to the context" do
    let(:hardware_id) { "8ba29d8a-3eae-4a83-9772-243b62b4b0c5" }
    let(:hardware) { LiudeskCMDB::Models::HardwareV1.new(ForemanLiudeskCMDB::API.client, hardware_id) }

    it "does nothing" do
      assert subject.success?
      assert subject._called.empty?
      refute_requested stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/search")
    end
  end
end

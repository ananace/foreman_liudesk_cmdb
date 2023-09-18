# frozen_string_literal: true

require "test_plugin_helper"

class UpdateHardwareTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::SyncHardware::Update.call(
      host: host,
      hardware: hardware,
      cmdb_params: host.liudesk_cmdb_facet.asset_parameters,
      cached_params: host.liudesk_cmdb_facet.cached_asset_parameters
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { nil }
  let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }
  let(:wanted_hardware_data) do
    {
      guid: hardware_id,
      make: "HP",
      model: "ProLiant DL480 Gen8",
      mac_and_network_access_roles: [
        {
          mac: "00:01:02:03:04:05",
          networkAccessRole: "None"
        }
      ],
      serial_number: "abc123",
      bios_uuid: "515bd9a2-d42a-4d4a-b57d-6ce464b549b8"
    }
  end
  let(:current_hardware_data) do
    {
      guid: hardware_id
    }
  end
  let(:hardware) do
    LiudeskCMDB::Models::HardwareV1.new(
      ForemanLiudeskCMDB::API.client,
      hardware_id
    )
  end
  let(:raw_data) do
    {
      hardware: wanted_hardware_data,
      hardware_type: "hardware_v1"
    }
  end
  let(:host) do
    FactoryBot.build_stubbed(:host, hostname: hostname).tap do |host|
      host.stubs(:facts).returns(
        "serialnumber" => "abc123",
        "manufacturer" => "HP",
        "productname" => "HP ProLiant DL480 Gen8",
        "uuid" => "515bd9a2-d42a-4d4a-b57d-6ce464b549b8"
      )
      host.interfaces.new mac: "00:01:02:03:04:05"

      facet = host.build_liudesk_cmdb_facet
      facet.asset_type = asset_type
      facet.network_role = network_role
      facet.hardware_id = hardware_id
      facet.asset_id = asset_id
      facet.raw_data = raw_data
    end
  end

  setup do
    setup_default_cmdb_settings
  end

  context "when hardware is not assigned" do
    let(:hardware) { nil }

    it "does nothing" do
      assert subject.success?
      assert subject._called.empty?
    end
  end

  context "when hardware is unchanged" do
    it "does nothing" do
      assert subject.success?
      refute_requested stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/#{hardware.api_url}")
    end
  end

  context "when hardware is modified" do
    let(:raw_data) { { hardware: current_hardware_data } }

    it "updates hardware" do
      updated = {
        serialNumber: "abc123",
        biosUuid: "515bd9a2-d42a-4d4a-b57d-6ce464b549b8",
        macAndNetworkAccessRoles: [
          {
            mac: "00:01:02:03:04:05",
            networkAccessRole: "None"
          }
        ]
      }
      stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/#{hardware.api_url}").with(
        body: updated
      ).to_return(
        status: 200,
        body: updated.merge(
          guid: hardware_id
        ).to_json
      )

      assert subject.success?
      assert_equal "515bd9a2-d42a-4d4a-b57d-6ce464b549b8", subject.hardware.bios_uuid
      assert_requested stub_patch
    end

    it "handles errors correctly" do
      stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/#{hardware.api_url}").to_return(
        status: 400,
        body: {}.to_json
      )

      refute subject.success?
      assert_requested stub_patch
    end
  end
end

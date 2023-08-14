# frozen_string_literal: true

require "test_plugin_helper"

class CreateHardwareTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::SyncHardware::Create.call(
      host: host,
      cmdb_params: host.liudesk_cmdb_facet.asset_parameters,
      hardware: hardware
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { nil }
  let(:hardware_id) { nil }
  let(:hardware) { nil }
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
    end
  end

  setup do
    setup_default_cmdb_settings
  end

  context "when hardware is not assigned to the context" do
    it "creates a hardware asset" do
      hardware_id = "96a933ed-5258-4070-9d4d-293e02e631bd"
      stub_post = stub_request(:post, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware").with(
        body: {
          macAndNetworkAccessRoles: [
            { mac: "00:01:02:03:04:05", networkAccessRole: "None" }
          ],
          make: "HP",
          model: "ProLiant DL480 Gen8",
          serialNumber: "abc123",
          biosUuid: "515bd9a2-d42a-4d4a-b57d-6ce464b549b8"
        }.to_json
      ).to_return(
        status: 201,
        body: {
          guid: hardware_id
        }.to_json
      )

      assert subject.success?
      assert_equal hardware_id, subject.hardware.identifier
      assert_requested stub_post
    end
  end

  context "when hardware is already assigned to the context" do
    let(:hardware_id) { "8ba29d8a-3eae-4a83-9772-243b62b4b0c5" }
    let(:hardware) { LiudeskCMDB::Models::HardwareV1.new(ForemanLiudeskCMDB::API.client, hardware_id) }

    it "does not create a hardware asset" do
      assert subject.success?
      assert subject._called.empty?
      refute_requested stub_request(:post, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware")
    end
  end
end

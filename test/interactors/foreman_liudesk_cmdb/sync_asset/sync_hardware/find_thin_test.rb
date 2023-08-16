# frozen_string_literal: true

require "test_plugin_helper"

class FindThinHardwareTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::SyncHardware::FindThin.call(
      host: host
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
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

  context "when hardware id is assigned in the facet" do
    let(:hardware_id) { "testdata" }
    it "finds a thin hardware object" do
      assert subject.success?
      assert_equal "testdata", subject.hardware.identifier
    end

    it "handles errors correctly" do
      ForemanLiudeskCMDB::API.expects(:get_asset).raises(StandardError)

      refute subject.success?
      refute subject.hardware
    end
  end

  context "when hardware id is not assigned to the facet" do
    it "does nothing" do
      assert subject.success?
      assert subject._called.empty?
      refute subject.hardware
    end
  end
end

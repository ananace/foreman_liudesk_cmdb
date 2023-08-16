# frozen_string_literal: true

require "test_plugin_helper"

class AttachThinHardwareArchiveTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::ArchiveAsset::AttachThinHardware.call(
      host: host
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
  let(:hardware_id) { nil }
  let(:host) do
    FactoryBot.build_stubbed(:host, hostname: hostname).tap do |host|
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

  context "when hardware id is assigned" do
    let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }

    it "attaches a thin hardware asset" do
      assert subject.success?
      refute subject._called.empty?
      assert_equal hardware_id, subject.hardware.identifier
    end

    it "handles failures correctly" do
      ForemanLiudeskCMDB::API.expects(:get_asset).raises(StandardError)

      refute subject.success?
      refute subject.hardware
    end
  end

  context "when hardware id is not assigned" do
    it "does not attach a thin hardware asset" do
      assert subject.success?
      assert subject._called.empty?
      assert_nil subject.hardware
    end
  end
end

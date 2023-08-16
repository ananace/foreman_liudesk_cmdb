# frozen_string_literal: true

require "test_plugin_helper"

class AttachThinAssetArchiveTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::ArchiveAsset::AttachThinAsset.call(
      host: host
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
  let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }
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

  context "when asset id is assigned" do
    it "attaches a thin asset" do
      assert subject.success?
      assert_equal hostname, subject.asset.identifier
    end

    it "handles failures correctly" do
      ForemanLiudeskCMDB::API.expects(:get_asset).raises(StandardError)

      refute subject.success?
      refute subject.asset
    end
  end

  context "when asset id is not assigned" do
    let(:asset_id) { nil }

    it "does not attach a thin asset" do
      assert subject.success?
      assert_nil subject.asset
    end
  end
end

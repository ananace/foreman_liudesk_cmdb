# frozen_string_literal: true

require "test_plugin_helper"

class UpdateFacetTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::UpdateFacet.call(
      host: host,
      asset: asset
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
  let(:asset) do
    LiudeskCMDB::Models::ServerV1.new(
      ForemanLiudeskCMDB::Api.client,
      asset_id
    )
  end

  setup do
    setup_default_cmdb_settings
  end

  context "when asset id is same" do
    it "does nothing" do
      assert subject.success?
      assert subject._called.empty?
    end
  end

  context "when asset id is missing" do
    it "updates facet asset id" do
      host.liudesk_cmdb_facet.asset_id = nil

      host.liudesk_cmdb_facet.expects(:update).with(asset_id: asset_id)

      assert subject.success?
    end

    it "handles errors correctly" do
      host.liudesk_cmdb_facet.asset_id = nil

      host.liudesk_cmdb_facet.expects(:update).raises(StandardError)

      refute subject.success?
    end
  end

  context "when asset id is changed" do
    it "updates facet asset id" do
      host.liudesk_cmdb_facet.asset_id = "#{hostname}-old"

      host.liudesk_cmdb_facet.expects(:update).with(asset_id: asset_id)

      assert subject.success?
    end

    it "handles errors correctly" do
      host.liudesk_cmdb_facet.asset_id = "#{hostname}-old"

      host.liudesk_cmdb_facet.expects(:update).raises(StandardError)

      refute subject.success?
    end
  end
end

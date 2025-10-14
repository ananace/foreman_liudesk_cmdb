# frozen_string_literal: true

require "test_plugin_helper"

class FindAssetTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::SyncAsset::Find.call(
      host: host,
      cmdb_params: host.liudesk_cmdb_facet.asset_parameters
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

  context "when asset id is not assigned" do
    let(:asset_id) { nil }

    it "attempts to acquire an asset" do
      stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/#{host.name}").to_return(
        status: 200,
        body: {
          hostName: host.name,
          hardwareID: "blah"
        }.to_json
      )

      assert subject.success?
      assert_equal hostname, subject.asset.identifier
      assert_requested stub_get
    end

    it "handles expected errors" do
      stub_get = stub_request(:get, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/#{host.name}").to_return(
        status: 404,
        body: {}.to_json
      )

      assert subject.success?
      refute subject.asset
      assert_requested stub_get
    end

    it "handles failures correctly" do
      ForemanLiudeskCMDB::Api.expects(:get_asset).raises(StandardError)

      refute subject.success?
      refute subject.asset
    end
  end

  context "when asset id is assigned" do
    it "does nothing" do
      assert subject.success?
      assert_nil subject.asset
    end
  end
end

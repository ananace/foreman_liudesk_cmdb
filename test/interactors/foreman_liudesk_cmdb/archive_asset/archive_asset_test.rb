# frozen_string_literal: true

require "test_plugin_helper"

class ArchiveAssetTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::ArchiveAsset::ArchiveAsset.call(
      host: host,
      asset: asset
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
  let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }
  let(:asset) do
    LiudeskCMDB::Models::ServerV1.new(
      ForemanLiudeskCMDB::API.client,
      asset_id
    )
  end
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

  context "when asset is not assigned" do
    let(:asset) { nil }

    it "does nothing" do
      assert subject.success?
      assert subject._called.empty?
    end
  end

  context "when asset is assigned" do
    it "deprecates the attached asset" do
      Time.stubs(:now).returns(Time.new(2020, 1, 1))
      stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/#{asset_id}").with(
        body: {
          hostName: "#{hostname}-depr-#{Time.now.to_i}"
        }
      ).to_return(
        status: 201,
        body: {
          hostName: "modified-hostname"
        }.to_json
      )
      stub_delete = stub_request(:delete, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/modified-hostname").to_return( # rubocop:disable Layout/LineLength
        status: 200
      )

      assert subject.success?
      assert_requested stub_patch
      assert_requested stub_delete
    end

    it "handles failures correctly" do
      Time.stubs(:now).returns(Time.new(2020, 1, 1))
      stub_patch = stub_request(:patch, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Server/#{asset_id}").with(
        body: {
          hostName: "#{hostname}-depr-#{Time.now.to_i}"
        }
      ).to_return(
        status: 400,
        body: {}.to_json
      )

      asset.expects(:delete!).never

      refute subject.success?
      assert_requested stub_patch
    end
  end
end

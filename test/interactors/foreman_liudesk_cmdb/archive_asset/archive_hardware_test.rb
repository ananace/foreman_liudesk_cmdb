# frozen_string_literal: true

require "test_plugin_helper"

class ArchiveHardwareTest < ActiveSupport::TestCase
  subject do
    ForemanLiudeskCMDB::ArchiveAsset::ArchiveHardware.call(
      host: host,
      hardware: hardware
    )
  end

  let(:hostname) { "host.dev.example.com" }
  let(:asset_type) { "server" }
  let(:network_role) { nil }
  let(:asset_id) { hostname }
  let(:hardware_id) { "c1de1e3d-5a3f-45b8-9dde-26e4f38872c0" }
  let(:hardware) do
    LiudeskCMDB::Models::HardwareV1.new(
      ForemanLiudeskCMDB::API.client,
      hardware_id
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

  context "when hardware is not assigned" do
    let(:hardware) { nil }

    it "does nothing" do
      assert subject.success?
      assert subject._called.empty?
    end
  end

  context "when hardware is assigned" do
    context "when host is physical" do
      it "does nothing" do
        assert subject.success?
        assert subject._called.empty?
      end
    end

    context "when host is virtual" do
      let(:host) do
        FactoryBot.build_stubbed(:host, hostname: hostname).tap do |host|
          host.compute_resource_id = 1
          host.uuid = "assigned"

          facet = host.build_liudesk_cmdb_facet
          facet.asset_type = asset_type
          facet.network_role = network_role
          facet.hardware_id = hardware_id
          facet.asset_id = asset_id
        end
      end

      it "deprecates the attached hardware" do
        stub_delete = stub_request(:delete, "#{Setting[:liudesk_cmdb_url]}/liudesk-cmdb/api/Hardware/#{hardware_id}").to_return( # rubocop:disable Layout/LineLength
          status: 200
        )

        assert subject.success?
        assert_requested stub_delete
      end

      it "handles failures correctly" do
        hardware.expects(:delete!).raises(StandardError)

        refute subject.success?
      end
    end
  end
end

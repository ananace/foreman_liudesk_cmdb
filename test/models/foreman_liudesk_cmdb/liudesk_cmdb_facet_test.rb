# frozen_string_literal: true

require "test_plugin_helper"

module Host
  class LiudeskCMDBFacetTest < ActiveSupport::TestCase
    let(:raw_data) do
      JSON.parse(File.read(File.join(File.dirname(__dir__), "..", "fixtures", "liudesk_cmdb_device_raw_data.json")))
    end
    let(:host) do
      FactoryBot.build(:host, :managed, :with_liudesk_cmdb_facet).tap do |host|
        host.liudesk_cmdb_facet.asset_type = "server"
        host.liudesk_cmdb_facet.raw_data = raw_data
      end
    end

    context "with host data stored" do
      setup do
        raw_data["asset"]["foreman_link"] = "https://foreman.example.com/hosts/"
        raw_data["asset"]["hostname"] = host.name
        raw_data["asset"]["certificate_information"] = host.name
        raw_data["asset"]["operating_system"] = host.os.title
        raw_data["asset"]["operating_system_type"] = host.os.name
        raw_data["asset"]["management_system_id"] = "#{SETTINGS[:fqdn]}/#{host.id}"
        raw_data["hardware"]["mac_and_network_access_roles"] = [
          {
            "mac" => host.primary_interface.mac.upcase,
            "networkAccessRole" => "None"
          }
        ]
        host.liudesk_cmdb_facet.clear_changes_information
      end

      it "will not consider itself to be changing" do
        refute host.liudesk_cmdb_facet.asset_will_change?
      end

      it "will consider asset_type changes to be changing" do
        host.liudesk_cmdb_facet.asset_type = "client"
        assert host.liudesk_cmdb_facet.asset_will_change?
      end

      it "will consider device data changes to be changing" do
        host.os = FactoryBot.build(:operatingsystem)
        assert host.liudesk_cmdb_facet.asset_will_change?
      end

      it "will only consider os changes to be changing asset" do
        host.os = FactoryBot.build(:operatingsystem)
        assert host.liudesk_cmdb_facet.asset_will_change? only: :asset
        refute host.liudesk_cmdb_facet.asset_will_change? only: :hardware
      end

      it "will only consider hardware changes to be changing hardware" do
        host.stubs(:facts).returns(
          "manufacturer" => "example manufacturer"
        )

        assert host.liudesk_cmdb_facet.asset_will_change? only: :hardware
        refute host.liudesk_cmdb_facet.asset_will_change? only: :asset
      end
      it "will consider data in ephemeral fields to be changes" do
        host.liudesk_cmdb_facet.set_ephemeral :asset, :misc_information, "Just a test value"

        assert host.liudesk_cmdb_facet.asset_will_change?
      end
      it "will consider nil data in ephemeral fields to be changes" do
        host.liudesk_cmdb_facet.set_ephemeral :asset, :misc_information, nil

        assert host.liudesk_cmdb_facet.asset_will_change?
      end
    end
  end
end

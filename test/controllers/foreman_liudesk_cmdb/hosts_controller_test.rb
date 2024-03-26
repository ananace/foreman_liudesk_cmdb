# frozen_string_literal: true

require "test_plugin_helper"

module ForemanLiudeskCMDB
  class HostsControllerTest < ActionController::TestCase
    tests ::HostsController

    setup do
      as_admin do
        host1
        host2
      end

      disable_orchestration
      setup_default_cmdb_settings
    end

    let(:hostgroup) { FactoryBot.create(:hostgroup, :with_liudesk_cmdb_facet) }
    let(:host1) { FactoryBot.create(:host, :with_liudesk_cmdb_facet, { hostgroup: hostgroup }) { |h| h.liudesk_cmdb_facet.asset_type = "server" } }
    let(:host2) { FactoryBot.create(:host) }

    describe "#edit" do
      setup do
        ForemanLiudeskCMDB::API.stubs(:network_access_roles).returns(%w[None Guest])
      end

      test "Host with CMDB facet should show misc edit fields" do
        get :edit, params: { id: host1.to_param }, session: set_session_user

        assert_includes response.body, "ephemeral_attributes"
      end

      test "Host with existing data should show said data in CMDB edit fields" do
        data = JSON.parse(File.read(File.join(File.dirname(__dir__), "..", "fixtures", "liudesk_cmdb_device_raw_data.json")))
        data["asset"]["misc_information"] = "Some CMDB testing data"
        host1.liudesk_cmdb_facet.raw_data = data
        host1.liudesk_cmdb_facet.save!

        get :edit, params: { id: host1.to_param }, session: set_session_user

        assert_includes response.body, "ephemeral_attributes"
        assert_includes response.body, "Some CMDB testing data"
      end

      test "Host without CMDB facet should not show misc edit fields" do
        refute host2.liudesk_cmdb_facet

        get :edit, params: { id: host2.to_param }, session: set_session_user

        refute_includes response.body, "ephemeral_attributes"
      end

      test "Host should set ephemeral CMDB attributes correctly" do
        finder = mock("Host")
        friendly = mock("ActiveRecord::Relation")
        finder.expects(:friendly).returns(friendly).at_least_once
        friendly.expects(:find).returns(host1).at_least_once

        HostsController.any_instance.expects(:resource_base).returns(finder).at_least_once

        put :update, params: {
          commit: "Update",
          id: host1.to_param,
          host: {
            liudesk_cmdb_facet_attributes: {
              ephemeral_attributes: {
                asset: {
                  misc_information: "Some new CMDB testing data"
                }
              }
            }
          }
        }, session: set_session_user

        assert_equal "Some new CMDB testing data", host1.liudesk_cmdb_facet.ephemeral_attributes[:asset][:misc_information]

        put :update, params: {
          commit: "Update",
          id: host1.to_param,
          host: {
            liudesk_cmdb_facet_attributes: {
              ephemeral_attributes: {
                asset: {
                  misc_information: ""
                }
              }
            }
          }
        }, session: set_session_user

        assert_nil host1.liudesk_cmdb_facet.ephemeral_attributes[:asset][:misc_information]
      end
    end
  end
end

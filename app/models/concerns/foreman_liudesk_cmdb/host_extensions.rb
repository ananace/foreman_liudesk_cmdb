# frozen_string_literal: true

module ForemanLiudeskCMDB
  # CMDB extensions
  #
  # Adds helper methods for working with client status and CMDB facet
  module HostExtensions
    extend ActiveSupport::Concern

    included do
      include ::Orchestration::LiudeskCMDB
    end

    def liudesk_cmdb_facet!(**attrs)
      return liudesk_cmdb_facet if liudesk_cmdb_facet && attrs.empty?

      attrs = liudesk_cmdb_facet.attributes.merge(attrs) if liudesk_cmdb_facet
      if hostgroup
        attrs = hostgroup.inherited_facet_attributes(Facets.registered_facets[:liudesk_cmdb_facet]).merge(attrs)
      end

      if liudesk_cmdb_facet
        f = liudesk_cmdb_facet
        f.update attrs
      else
        f = build_liudesk_cmdb_facet attrs
        f.save if persisted?
      end

      f
    end

    def refresh_cmdb_status
      refresh_statuses([HostStatus::CMDBStatus])
    end
  end
end

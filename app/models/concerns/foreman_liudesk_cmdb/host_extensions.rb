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
      attrs = hostgroup.inherited_facet_attributes(Facets.registered_facets[:liudesk_cmdb_facet]).merge(attrs) \
        if hostgroup

      if liudesk_cmdb_facet
        f = liudesk_cmdb_facet
        f.update_attributes attrs
      else
        f = build_liudesk_cmdb_facet attrs
        f.save if persisted?
      end

      f
    end
  end
end

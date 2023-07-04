# frozen_string_literal: true

# Wrapper for the CMDB API client
#
# Handles converting asset type symbols into models
class LiudeskCMDBServer < ApplicationRecord
  # Allows reading the name in safemode
  class Jail < Safemode::Jail
    allow :name
  end

  include Encryptable
  include Parameterizable::ByIdName
  extend FriendlyId

  friendly_id :name
  encrypts :apikey

  validates_lengths_from_database

  audited except: [:apikey]
  has_associated_audits

  before_destroy EnsureNotUsedBy.new(:hosts)

  has_many :liudesk_cmdb_facets,
           class_name: "ForemanLiudeskCMDB::LiudeskCMDBFacet",
           dependent: :nullify,
           inverse_of: :liudesk_cmdb_server
  has_many :liudesk_cmdb_hostgroup_facets,
           class_name: "ForemanLiudeskCMDB::LiudeskCMDBHostgroupFacet",
           dependent: :nullify,
           inverse_of: :liudesk_cmdb_server

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true
  validates :apikey, presence: true

  scoped_search on: :name, complete_value: true
  default_scope -> { order("liudesk_cmdb_servers.name") }

  def get_asset(asset_type, asset_id, thin: false)
    klass = LiudeskCMDB::Models.const_get(asset_type.to_s.camel_case(capitalized: true).to_sym)
    return klass.new connection, asset_id if thin

    klass.get connection, asset_id
  end

  def find_asset(asset_type, **search)
    klass = LiudeskCMDB::Models.const_get(asset_type.to_s.camel_case(capitalized: true).to_sym)
    klass.search connection, op: :or, **search
  end

  def create_asset(asset_type, save: true, **data)
    klass = LiudeskCMDB::Models.const_get(asset_type.to_s.camel_case(capitalized: true).to_sym)
    asset = klass.new connection, **data
    asset.create if save
    asset
  end

  private

  def connection
    @connection ||= LiudeskCMDB::Client.new url, subscription_key: apikey
  end
end

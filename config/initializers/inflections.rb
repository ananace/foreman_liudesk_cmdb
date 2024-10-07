# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'cmdb_status' => 'CMDBStatus',
    'foreman_liudesk_cmdb' => 'ForemanLiudeskCMDB',
    'liudesk_cmdb' => 'LiudeskCMDB',
    'liudesk_cmdb_facet' => 'LiudeskCMDBFacet',
    'liudesk_cmdb_hostgroup_facet' => 'LiudeskCMDBHostgroupFacet',
  )
end

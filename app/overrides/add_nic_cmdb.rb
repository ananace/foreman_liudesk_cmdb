# frozen_string_literal: true

%w[bonds/_bond bridges/_bridge manageds/_managed].each do |type|
  Deface::Override.new(virtual_path: "nic/#{type}",
                       name: "add_liudesk_cmdb_nic_#{type.split("/").first[..-2]}_options",
                       insert_after: ":last-child",
                       partial: "foreman_liudesk_cmdb/nic_cmdb_options")
end

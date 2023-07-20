# frozen_string_literal: true

Deface::Override.new(virtual_path: "hosts/_form",
                     name: "add_liudesk_cmdb_server_selection",
                     insert_bottom: "#primary",
                     partial: "foreman_liudesk_cmdb/host_cmdb_options")

Deface::Override.new(virtual_path: "hostgroups/_form",
                     name: "hg_add_liudesk_cmdb_server_selection",
                     insert_bottom: "#primary",
                     partial: "foreman_liudesk_cmdb/host_cmdb_options")

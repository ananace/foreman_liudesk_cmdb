# frozen_string_literal: true

Deface::Override.new(virtual_path: "hosts/_form",
                     name: "add_liudesk_cmdb_tab",
                     insert_bottom: ".nav-tabs",
                     text: '<li><a href="#cmdb" data-toggle="tab">CMDB</a></li>')

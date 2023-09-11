function cmdb_asset_type_changed(element) {
  var show_cmdb = $(element).val() !== '';

  var role_divs = $('div.clearfix:has(select[name$="[network_role]"],select[name$="[hardware_fallback_role]"])');
  if (show_cmdb) {
    role_divs.removeClass('hidden');
  } else {
    role_divs.addClass('hidden');
  }

  if ($(element).val() === 'server') {
    $('div.clearfix:has(select[name^="host[liudesk"][name$="[network_role]"])').addClass('hidden');
  }
}

$(function() {
  cmdb_asset_type_changed($('select[name$="[asset_type]"]'));
});

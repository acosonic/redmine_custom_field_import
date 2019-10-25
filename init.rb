Redmine::Plugin.register :redmine_custom_field_import do
  name 'Redmine Custom Field value Import plugin'
  author 'Bilel kedidi'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  author_url 'https://www.github.com/bilel-kedidi'

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :custom_field_import, { controller: 'custom_field_import', action: 'import', id: 'custom_field_import' }, caption: 'Custom Value Import'
  end

end

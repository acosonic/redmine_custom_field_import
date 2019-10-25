# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#
match 'custom_field_import/:action', controller: :custom_field_import, via: [:get, :post]
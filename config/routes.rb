#    This file is part of Monzo-Viewer.

#    Monzo-Viewer is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.

#    Monzo-Viewer is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Monzo-Viewer.  If not, see <https://www.gnu.org/licenses/>.

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "account#viewall"
  get "create_account" => "setup#create_account", as: "create_account"
  post "create_account/create" => "setup#create_user", as: "create_user"
  get "first_run/dev_portal" => "setup#dev_portal", as: "dev_portal"
  get "first_run/oauth_details" => "setup#oauth_details", as: "oauth_details"
  post "first_run/authorisation_setup" => "setup#authorisation_setup", as: "authorisation_setup"
  get "first_run/complete_authorisation" => "setup#complete_authorisation", as: "complete_authorisation"
  get "first_run/start_afresh" => "setup#start_afresh", as: "start_afresh"
  get "login" => "sessions#login", as: "login"
  get "login_error" => "sessions#login_error", as: "login_error"
  post "login_submit" => "sessions#login_submit", as: "login_submit"
  get "logout" => "sessions#logout", as: "logout"
  get "accounts" => "account#viewall", as: "accounts"
  get "account/:id" => "account#view", as: "account"
  get "account/:id/graph" => "account#graph", as: "account_graph"
  get "accounts/settings" => "account#settings", as: "user_settings"
  get "account/:id/:transactionoffset" => "account#view", as: "account_view_offset"
  post "account/:id/create_pot_condition" => "account#create_pot_condition", as: "create_pot_condition"
  delete "account/:id/delete_pot_condition/:conditionid" => "account#delete_pot_condition", as: "delete_pot_condition"
  get "account/:id/pot/:potid" => "account#pot", as: "pot_view"
  post "account/:id/pot/:potid/create_target" => "account#create_target", as: "create_target"
  delete "account/:id/pot/:potid/delete_target/:targetid" => "account#delete_target", as: "delete_target"
  patch "account/:id" => "account#update", as: "account_update"
  get "account/:id/transfer_to_pot/:amount/:transaction" => "account#transfer_to_pot", as: "transfer_to_pot"
  get "accounts/update" => "account#update_accounts", as: "update_accounts"
  get "accounts/update/:force" => "account#update_accounts", as: "force_update_accounts"
end

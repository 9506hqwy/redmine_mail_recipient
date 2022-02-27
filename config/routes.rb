# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  resources :projects do
    put '/mail_recipient', to: 'mail_recipients#update', format: false
  end
end

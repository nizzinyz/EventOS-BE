Rails.application.routes.draw do
  # Root — return a small JSON payload instead of the default Rails welcome page.
  root to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }

  # ── Devise (auth lives at /api/auth/…) ──────────────────────────────────────
  devise_for :users,
    path: "api/auth",
    controllers: {
      sessions:            "api/auth/sessions",
      registrations:       "api/auth/registrations",
      passwords:           "api/auth/passwords",
      confirmations:       "api/auth/confirmations",
      omniauth_callbacks:  "api/auth/omniauth_callbacks"
    }

  # One-time code exchange: completes the OAuth flow without a JWT in any URL.
  # POST /api/auth/exchange  →  api/auth/exchanges#create
  post "api/auth/exchange", to: "api/auth/exchanges#create"
  post "api/auth/auth0_session", to: "api/auth/sessions#auth0_session"

  # ── API resources ────────────────────────────────────────────────────────────
  namespace :api do
    resource :config, only: :show, controller: "config"
    resources :orders, only: [:index, :create]
    resources :events do
      resources :check_ins, only: :create
      resources :members, only: [:index, :create, :destroy], controller: "event_members"
      resource :reaction, only: [:show, :update], controller: "event_reactions"
    end
    resources :venue_bookings, only: [:index, :create]
    get "owner_dashboard", to: "owner_dashboard#show"
    get "venues/:venue_id/slots", to: "venue_bookings#slots"
    resources :venues
    resources :venues, only: [] do
      resource :verification_submission, only: [:show, :create], controller: "venue_verification_submissions"
    end
    get "admin/users", to: "admin#users"
    patch "admin/users/:id/role", to: "admin#update_user_role"
    get "admin/verification_submissions", to: "admin#verification_submissions"
    patch "admin/verification_submissions/:id/review", to: "admin#review_verification"
    resources :tickets, only: [:index, :create]
    resources :booking_requests, only: [:index, :create, :update]
    resources :users, only: [:show, :update, :destroy]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

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

  # ── API resources ────────────────────────────────────────────────────────────
  namespace :api do
    resources :users, only: [:show, :update, :destroy]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

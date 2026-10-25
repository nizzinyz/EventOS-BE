module Api
  class ConfigController < ApplicationController
    # Public feature flags are needed before a visitor has a Roam session.
    skip_before_action :authenticate_request!, only: :show

    def show
      render json: { localPreview: LocalPreview.enabled?, mockCheckout: LocalPreview.enabled?, currency: "ZAR" }
    end
  end
end

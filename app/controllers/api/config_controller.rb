module Api
  class ConfigController < ApplicationController
    skip_before_action :authenticate_user!

    def show
      render json: { localPreview: LocalPreview.enabled?, mockCheckout: LocalPreview.enabled?, currency: "ZAR" }
    end
  end
end

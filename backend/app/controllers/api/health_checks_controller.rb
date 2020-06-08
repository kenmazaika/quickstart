class Api::HealthChecksController < ApplicationController
    def index
        resp = {
          time: Time.now.to_s(:db),
          env: Rails.env.to_s,
          message: "Alpha pass thru x 3"
        }
        render json: resp
      end
end

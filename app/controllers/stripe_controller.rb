class StripeController < ApplicationController
  protect_from_forgery except: :webhook
  skip_before_action :require_login

  def webhook
    #event = JSON.parse params
    render status: 200, json: {message: "webhook received"}
  end
end

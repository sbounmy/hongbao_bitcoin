class TokensController < ApplicationController
  allow_unauthenticated_access only: [ :paid ]
  skip_before_action :verify_authenticity_token, only: [ :paid ]

  def create
  end

  def paid
    result = Tokens::Paid.call(payload: request.body.read, sig_header: request.env["HTTP_STRIPE_SIGNATURE"])
    if result.success?
      render json: { message: :success }
    else
      render json: { error: { message: result.error.message } }, status: :bad_request
    end
  end
end

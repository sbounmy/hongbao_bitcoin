class HongBaosController < ApplicationController
  def new
    @hong_bao = HongBao.new(hong_bao_params)
  end

  def create
    @hong_bao = HongBao.new(hong_bao_params)

    if @hong_bao.valid?
      session = Stripe::Checkout::Session.create(
        payment_method_types: [ "card" ],
        line_items: [ {
          price_data: {
            currency: "usd",
            unit_amount: @hong_bao.total_amount_cents,
            product_data: {
              name: "Bitcoin Hong Bao"
            }
          },
          quantity: 1
        } ],
        mode: "payment",
        success_url: success_hong_bao_url(@hong_bao),
        cancel_url: new_hong_bao_url
      )

      @hong_bao.update(stripe_session_id: session.id)
      redirect_to session.url, allow_other_host: true
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @hong_bao = HongBao.find(params[:id])
  end

  def print
    @hong_bao = HongBao.find(params[:id])
    render layout: "print"
  end

  private

  def hong_bao_params
    params.fetch(:hong_bao, {}).permit(:amount, :recipient_name, :message)
  end
end

class GettingStartedController < ApplicationController
  allow_unauthenticated_access

  def show
    @step = params[:step].to_i.presence || 1
    @total_steps = 5

    # Validate step range
    if @step < 1 || @step > @total_steps
      redirect_to getting_started_path(step: 1)
    end

    # Load scanned address for step 3
    if @step == 3 && session[:scanned_address]
      @hong_bao = HongBao.new(scanned_key: session[:scanned_address])
      @scanned_address = session[:scanned_address]
    end
  end

  def create
    @hong_bao = HongBao.from_scan(params[:address])
    if @hong_bao.present?
      session[:scanned_address] = params[:address]
      session[:private_key] = @hong_bao.private_key if @hong_bao.private_key.present?
      redirect_to getting_started_path(step: 3)
    else
      redirect_to getting_started_path(step: 2), alert: "Invalid Bitcoin address"
    end
  end
end

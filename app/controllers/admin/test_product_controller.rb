module Admin
  class TestProductController < ApplicationController
    before_action :require_admin

    def show
      @product = StripeService.fetch_admin_product
    rescue ::Stripe::StripeError => e
      flash[:alert] = "Unable to load product: #{e.message}"
      redirect_to root_path
    end

    private

    def require_admin
      unless current_user&.admin?
        flash[:alert] = "Access denied. Admin privileges required."
        redirect_to root_path
      end
    end
  end
end

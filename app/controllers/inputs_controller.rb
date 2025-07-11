class InputsController < ApplicationController
  allow_unauthenticated_access

  def show
    @input = Input.find(params[:id])
    if @input.renderable
      render "inputs/#{@input.type.split("::").last.downcase.pluralize}/show"
    else
      render plain: "Not found", status: :not_found
    end
  end

end
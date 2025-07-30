class InputsController < ApplicationController
  allow_unauthenticated_access
  layout "main"

  def show
    @input = Input.friendly.find(params[:id])
    @papers = Paper.with_all_input_ids(@input.id).order(created_at: :desc)

    if @input.renderable
      render "inputs/#{@input.type.split("::").last.downcase.pluralize}/show"
    else
      render plain: "Not found", status: :not_found
    end
  end
end

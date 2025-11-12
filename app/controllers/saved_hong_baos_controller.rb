class SavedHongBaosController < ApplicationController
  layout "main"
  before_action :set_saved_hong_bao, only: [:edit, :destroy, :refresh, :update, :destroy_file, :download ]
  before_action :set_network, only: [ :create ]

  def index
    @saved_hong_baos = current_user.saved_hong_baos.order_by_gifted_at
  end

  def new
    @saved_hong_bao = current_user.saved_hong_baos.build(address: params[:address])
  end

  def create
    @saved_hong_bao = current_user.saved_hong_baos.build(saved_hong_bao_params)

    if @saved_hong_bao.save
      # Model broadcasts automatically via after_create_commit callback
      redirect_to saved_hong_baos_path, notice: "Hong Bao saved! Fetching balance..."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # For turbo frame modal
  end

  def destroy
    @saved_hong_bao.destroy
    redirect_to saved_hong_baos_path, notice: "Hong Bao removed from saved list."
  end

  def refresh
    RefreshSavedHongBaoBalanceJob.perform_later(@saved_hong_bao.id)
    redirect_to saved_hong_baos_path, notice: "Balance refresh initiated. Please wait a moment."
  end

  def update
    if @saved_hong_bao.update(saved_hong_bao_params)
      redirect_to saved_hong_baos_path, notice: "Hong Bao updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy_file
    @saved_hong_bao.file.purge
    flash.now[:notice] = "File removed successfully."
    render :edit
  end

  def download
    if @saved_hong_bao.file.attached?
      redirect_to rails_blob_path(@saved_hong_bao.file, disposition: "attachment")
    else
      redirect_back fallback_location: saved_hong_baos_path, alert: "No file attached."
    end
  end

  private

  def set_saved_hong_bao
    @saved_hong_bao = current_user.saved_hong_baos.find(params[:id])
  end

  def saved_hong_bao_params
    params.require(:saved_hong_bao).permit(:name, :address, :notes, :status, :status_changed_at, :file)
  end

  def set_network
    Current.network = Current.network_from_key(saved_hong_bao_params[:address])
  end
end

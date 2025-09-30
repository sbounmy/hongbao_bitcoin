ActiveAdmin.register ActiveStorage::Attachment, as: "Attachment" do
  menu false  # Hide from menu since this is just for utility

  # Only allow delete action
  actions :destroy

  controller do
    def destroy
      @attachment = ActiveStorage::Attachment.find(params[:id])
      @attachment.purge
      redirect_back fallback_location: admin_root_path, notice: "Image deleted successfully."
    end
  end
end

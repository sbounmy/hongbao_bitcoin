ActiveAdmin.register Ai::Element do
  permit_params :leonardo_id, :title, :weight, :status, :leonardo_created_at, :leonardo_updated_at
  action_item :sync_elements, only: :index do
    link_to "Sync Elements from Leonardo", sync_elements_admin_ai_elements_path, method: :post
  end
  collection_action :sync_elements, method: :post do
    SyncLeonardoElementsJob.perform_later
    redirect_to admin_ai_elements_path, notice: "Element sync started. Please refresh in a few moments."
  end

  index do
    selectable_column
    id_column
    column :leonardo_id
    column :title
    column :weight
    column :status
    column :leonardo_created_at
    column :leonardo_updated_at
    column :created_at
    actions
  end

  filter :leonardo_id
  filter :title
  filter :weight
  filter :status
  filter :leonardo_created_at
  filter :leonardo_updated_at
  filter :created_at

  form do |f|
    f.inputs do
      f.input :leonardo_id
      f.input :title
      f.input :weight
      f.input :status
      f.input :leonardo_created_at
      f.input :leonardo_updated_at
    end
    f.actions
  end

  show do
    attributes_table do
      row :leonardo_id
      row :title
      row :weight
      row :status
      row :leonardo_created_at
      row :leonardo_updated_at
      row :created_at
      row :updated_at
    end
  end
end

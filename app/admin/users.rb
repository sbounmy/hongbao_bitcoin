ActiveAdmin.register User do
  permit_params :email, :admin

  filter :email
  filter :admin
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :email
    column :admin
    column :avatar do |user|
      if user.avatar.attached?
        image_tag url_for(user.avatar), width: 100
      end
    end
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs "User Details" do
      f.input :email
      f.input :admin
    end
    f.actions
  end

  show do
    attributes_table do
      row :email
      row :admin
      row :avatar do |user|
        if user.avatar.attached?
          image_tag url_for(user.avatar), width: 100
        end
      end
    end
  end
end

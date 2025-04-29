ActiveAdmin.register Input::Theme do
  form do |f|
    f.inputs do
      f.input :name
      f.input :image, as: :file
    end
  f.actions
  end
end

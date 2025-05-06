ActiveAdmin.register Paper do
  permit_params :name, :year, :active, :position, :public, :user_id,
                :image_front, :image_back,
                elements: Paper::ELEMENTS.map { |e| [ e.to_sym, Paper::ELEMENT_ATTRIBUTES ] }.to_h

  remove_filter :image_front_attachment
  remove_filter :image_back_attachment

  filter :name
  filter :active
  filter :public
  filter :user
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :active
    column :public
    column :user do |paper|
      paper.user.email if paper.user
    end
    column :position
    column :image_front do |paper|
      if paper.image_front.attached?
        image_tag url_for(paper.image_front)
      end
    end
    column :image_back do |paper|
      if paper.image_back.attached?
        image_tag url_for(paper.image_back)
      end
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :active
      row :public
      row :user do |paper|
        paper.user.email if paper.user
      end
      row :position
      row :image_front do |paper|
        if paper.image_front.attached?
          image_tag url_for(paper.image_front)
        end
      end
      row :image_back do |paper|
        if paper.image_back.attached?
          image_tag url_for(paper.image_back)
        end
      end

      # Display JSONB elements
      Paper::ELEMENTS.each do |element|
        panel element.titleize do
          attributes_table_for paper.elements[element] do
            Paper::ELEMENT_ATTRIBUTES.each do |attribute|
              row attribute do
                paper.elements[element][attribute]
              end
            end
          end
        end
      end
    end
  end

  form html: { multipart: true } do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs do
      f.input :name
      f.input :active
      f.input :public
      f.input :user, collection: User.all.map { |u| [ u.email, u.id ] }, required: false
      f.input :position
      f.input :image_front, as: :file, hint: f.object.image_front.attached? ? image_tag(url_for(f.object.image_front)) : nil
      f.input :image_back, as: :file, hint: f.object.image_back.attached? ? image_tag(url_for(f.object.image_back)) : nil

      # JSONB elements handling
      Paper::ELEMENTS.each do |element|
        f.inputs element.titleize do
          Paper::ELEMENT_ATTRIBUTES.each do |attribute|
            f.input "elements_#{element}_#{attribute}",
                    label: attribute.to_s.titleize,
                    input_html: {
                      value: f.object.elements&.dig(element, attribute.to_s),
                      name: "paper[elements][#{element}][#{attribute}]"
                    }
          end
        end
      end
    end
    f.actions
  end
end

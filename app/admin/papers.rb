ActiveAdmin.register Paper do
  permit_params :name, :year, :style, :active, :position,
                :image_front, :image_back,
                elements: Paper::ELEMENTS.map { |e| [ e.to_sym, Paper::ELEMENT_ATTRIBUTES ] }.to_h

  remove_filter :image_front_attachment
  remove_filter :image_back_attachment
  remove_filter :style

  filter :name
  filter :active
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :style
    column :active
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
      row :style
      row :active
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
              row attribute
            end
          end
        end
      end
    end
  end

  form html: { multipart: true } do |f|
    f.inputs do
      f.input :name
      f.input :style
      f.input :active
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

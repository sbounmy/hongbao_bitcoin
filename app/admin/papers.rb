ActiveAdmin.register Paper do
  permit_params :name, :year, :active, :public, :user_id,
                :image_front, :image_back, :image_full,
                { elements: Paper::ELEMENTS.map { |e| [ e.to_sym, Paper::ELEMENT_ATTRIBUTES ] }.to_h },
                :bundle_id, :parent_id, :task_id,
                *Paper::ELEMENTS.map { |el| { "elements_#{el}".to_sym => Paper::ELEMENT_ATTRIBUTES } }

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
    column :user do |paper|
      paper.user.email if paper.user
    end
    column :image_full do |paper|
      if paper.image_full.attached?
        image_tag url_for(paper.image_full), width: 100
      end
    end
    column :image_front do |paper|
      if paper.image_front.attached?
        image_tag url_for(paper.image_front), width: 100
      end
    end
    column :image_back do |paper|
      if paper.image_back.attached?
        image_tag url_for(paper.image_back), width: 100
      end
    end
    actions defaults: true do |paper_instance|
      item "Duplicate", duplicate_admin_paper_path(paper_instance),
           method: :post,
           data: { confirm: "Are you sure you want to duplicate this paper and its images?" }
    end
  end

  show do
    attributes_table do
      row :name
      row :active
      row :public
      row :user do |paper|
        paper.user.email if paper.user
      end

      row :image_full do |paper|
        if paper.image_full.attached?
          image_tag url_for(paper.image_full), width: 500
        end
      end
      row :image_front do |paper|
        if paper.image_front.attached?
          image_tag url_for(paper.image_front), width: 500
        end
      end
      row :image_back do |paper|
        if paper.image_back.attached?
          image_tag url_for(paper.image_back), width: 500
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

  action_item :duplicate, only: :show do
    link_to "Duplicate Paper", duplicate_admin_paper_path(resource),
            method: :post,
            data: { confirm: "Are you sure you want to duplicate this paper and its images?" }
  end

  form html: { multipart: true } do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs do
      f.input :name
      f.input :active
      f.input :public
      f.input :user, collection: User.all.map { |u| [ u.email, u.id ] }, required: false
      f.input :image_full, as: :file, hint: f.object.image_full.attached? ? image_tag(url_for(f.object.image_full), width: 500) : nil
      f.input :image_front, as: :file, hint: f.object.image_front.attached? ? image_tag(url_for(f.object.image_front), width: 500) : nil
      f.input :image_back, as: :file, hint: f.object.image_back.attached? ? image_tag(url_for(f.object.image_back), width: 500) : nil

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

  member_action :duplicate, method: :post do
    original_paper = Paper.find(params[:id])
    new_paper = original_paper.dup

    new_paper.name = "Copy of #{original_paper.name} - #{SecureRandom.hex(4)}"

    if original_paper.image_front.attached?
      new_paper.image_front.attach(original_paper.image_front.blob)
    end

    if original_paper.image_back.attached?
      new_paper.image_back.attach(original_paper.image_back.blob)
    end

    if original_paper.image_full.attached?
      new_paper.image_full.attach(original_paper.image_full.blob)
    end

    if new_paper.save
      redirect_to admin_paper_path(new_paper), notice: "Paper was successfully duplicated."
    else
      redirect_to admin_paper_path(original_paper), alert: "Failed to duplicate paper: #{new_paper.errors.full_messages.join(', ')}"
    end
  end
end

ActiveAdmin.register Paper do
  permit_params :name, :year, :active, :public, :user_id,
                :image_front, :image_back, :image_full,
                { elements: Paper::ELEMENTS.map { |e| [ e.to_sym, Paper::ELEMENT_ATTRIBUTES ] }.to_h },
                :bundle_id, :parent_id, :task_id, { tag_ids: [] },
                *Paper::ELEMENTS.map { |el| { "elements_#{el}".to_sym => Paper::ELEMENT_ATTRIBUTES } }

  remove_filter :image_front_attachment
  remove_filter :image_back_attachment

  filter :name
  filter :active
  filter :public
  filter :user
  filter :tag_ids, as: :select, collection: -> { Tag.for_category(:papers) }
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :tags do |paper|
      paper.tag_names.map { |name| status_tag name }
      []
    end
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

    column :image_portrait do |paper|
      if paper.image_portrait.attached?
        image_tag url_for(paper.image_portrait), width: 100
      end
    end

    column :total_tokens
    column :total_costs

    actions defaults: true do |paper_instance|
      item "Duplicate", duplicate_admin_paper_path(paper_instance),
           method: :post,
           data: { confirm: "Are you sure you want to duplicate this paper and its images?" }
      if paper_instance.image_portrait.attached?
        item "Recomposite", recomposite_admin_paper_path(paper_instance),
             method: :post,
             data: { confirm: "Regenerate front image using existing portrait?" }
      end
    end
  end

  show do
    attributes_table do
      row :name
      row :tags do |paper|
        paper.tag_names.map { |name| status_tag name, class: "yes" }
        []
      end
      row :active
      row :public

      row :total_tokens
      row :total_costs
      row :prompt

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

      row :image_portrait do |paper|
        if paper.image_portrait.attached?
          image_tag url_for(paper.image_portrait), width: 500
        end
      end

      # Display Input::Image (original)
      row :input_image_original do |paper|
        image_input = paper.input_items.find { |item| item.input.type == "Input::Image" }
        if image_input&.image&.attached?
          image_tag url_for(image_input.image), width: 500
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

  action_item :recomposite, only: :show do
    if resource.image_portrait.attached?
      link_to "Recomposite Front Image", recomposite_admin_paper_path(resource),
              method: :post,
              data: { confirm: "Regenerate front image using existing portrait and current theme configuration?" }
    end
  end

  form html: { multipart: true } do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs do
      f.input :name
      f.input :tag_ids, collection: Tag.for_category(:papers), as: :select, multiple: true, include_blank: "None"
      f.input :active
      f.input :public
      f.input :user, collection: User.all.map { |u| [ u.email, u.id ] }, required: false
      f.input :image_full, as: :file, hint: f.object.image_full.attached? ? image_tag(url_for(f.object.image_full), width: 500) : nil
      f.input :image_front, as: :file, hint: f.object.image_front.attached? ? image_tag(url_for(f.object.image_front), width: 500) : nil
      f.input :image_back, as: :file, hint: f.object.image_back.attached? ? image_tag(url_for(f.object.image_back), width: 500) : nil

      f.inputs "Visual Element Editor" do
        para "Position elements visually on your paper images. Elements unique to Papers are managed below."
        render Admin::VisualEditorComponent.new(form: f, input_base_name: "paper[elements]")
      end
      # JSONB elements handling
      paper_only_elements = Paper::ELEMENTS - Input::Theme::AI_ELEMENT_TYPES
      if paper_only_elements.any?
        f.inputs "Paper-Specific Elements" do
          paper_only_elements.each do |element|
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

  member_action :recomposite, method: :post do
    require "stringio"
    require "vips"

    paper = Paper.find(params[:id])

    unless paper.image_portrait.attached?
      redirect_to admin_paper_path(paper), alert: "No portrait image found. Cannot recomposite."
      return
    end

    # Get theme input to access template and portrait config
    input_items = paper.input_items
    theme_input = input_items.find { |item| item.input.type == "Input::Theme" }&.input

    unless theme_input
      redirect_to admin_paper_path(paper), alert: "No theme found. Cannot recomposite."
      return
    end

    begin
      Rails.logger.info "[Admin] Recompositing Paper #{paper.id}"

      # Get portrait blob
      portrait_blob = paper.image_portrait.download

      # Composite styled portrait onto template
      composed_image = Papers::Composition.call(
        template: theme_input.image_front,
        portrait: portrait_blob,
        config: theme_input.portrait_config
      )

      # Attach new composed front image
      paper.image_front.attach(
        io: StringIO.new(composed_image),
        filename: "front_recomposed_#{SecureRandom.hex(4)}.jpg"
      )

      redirect_to admin_paper_path(paper), notice: "Front image successfully recomposited!"
      # rescue => e
      #   Rails.logger.error "[Admin] Recomposite failed: #{e.message}"
      #   redirect_to admin_paper_path(paper), alert: "Failed to recomposite: #{e.message}"
    end
  end
end

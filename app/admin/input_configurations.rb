ActiveAdmin.register Input::Configuration, as: "Configuration" do
  menu parent: "Inputs", priority: 10, label: "Configuration"

  permit_params :prompt

  # Only show edit action, no index or show
  actions :edit, :update

  # Redirect index to edit the singleton instance
  controller do
    def index
      redirect_to edit_admin_configuration_path(Input::Configuration.instance)
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "AI Base Prompt Configuration" do
      para "This prompt will be prepended to all AI style generation requests. Use it for consistent framing, quality, and formatting requirements."

      f.input :prompt, as: :text, input_html: { rows: 15 },
              label: "Base AI Prompt",
              hint: "Example: Instructions for cropping, framing, background, resolution, etc."
    end

    f.actions do
      f.action :submit, label: "Save Configuration"
      f.cancel_link admin_dashboard_path
    end
  end
end

require 'rails_helper'

RSpec.describe FormErrorsComponent, type: :component do
  let(:model) { double('model') }

  it "renders errors when present" do
    allow(model).to receive(:errors).and_return(
      double('errors', any?: true, full_messages: ['Name is required', 'Address is invalid'])
    )

    component = described_class.new(model: model)
    render_inline(component)

    expect(rendered_content).to have_css('.alert-error')
    expect(rendered_content).to have_text('Name is required')
    expect(rendered_content).to have_text('Address is invalid')
  end

  it "does not render when no errors" do
    allow(model).to receive(:errors).and_return(
      double('errors', any?: false)
    )

    component = described_class.new(model: model)
    render_inline(component)

    expect(rendered_content).to be_blank
  end

  it "does not render when model is nil" do
    component = described_class.new(model: nil)
    render_inline(component)

    expect(rendered_content).to be_blank
  end
end
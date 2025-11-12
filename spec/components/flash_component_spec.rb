require 'rails_helper'

RSpec.describe FlashComponent, type: :component do
  it "renders success flash" do
    component = described_class.new(type: :notice, message: "Success!")

    render_inline(component)

    expect(rendered_content).to have_css('.alert-success')
    expect(rendered_content).to have_text('Success!')
  end

  it "renders error flash" do
    component = described_class.new(type: :error, message: "Error!")

    render_inline(component)

    expect(rendered_content).to have_css('.alert-error')
    expect(rendered_content).to have_text('Error!')
  end

  it "does not render when message is blank" do
    component = described_class.new(type: :notice, message: nil)

    render_inline(component)

    expect(rendered_content).to be_blank
  end
end
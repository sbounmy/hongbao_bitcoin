require "rails_helper"

RSpec.describe Contents::Quotes::JsonLdComponent, type: :component do
  let(:quote) do
    Content::Quote.new(
      text: "No man should work for what another man can print",
      author: "Jack Mallers",
      published_at: Time.parse("2024-01-01"),
      created_at: Time.parse("2024-01-01")
    )
  end

  let(:component) { described_class.new(quote: quote) }

  it "renders JSON-LD script tag" do
    rendered = render_inline(component)

    expect(rendered.css('script[type="application/ld+json"]')).to be_present
  end

  it "includes quote text and author" do
    rendered = render_inline(component).to_html

    expect(rendered).to include('"@type": "Quotation"')
    expect(rendered).to include('"text": "No man should work for what another man can print"')
    expect(rendered).to include('"name": "Jack Mallers"')
  end

  it "includes image URL from fallback" do
    rendered = render_inline(component).to_html

    # Since quote has no hongbao_products or avatar, it should use the fallback image
    expect(rendered).to include('"image":')
    expect(rendered).to include('bill_hongbao')
  end

  it "generates valid JSON" do
    rendered = render_inline(component).to_html
    script_content = rendered.match(/<script[^>]*>(.*?)<\/script>/m)[1]

    expect { JSON.parse(script_content) }.not_to raise_error
  end
end

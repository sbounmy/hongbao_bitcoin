require "rails_helper"

RSpec.describe JsonLdComponent, type: :component do
  # Test subclass for testing base functionality
  class TestJsonLdComponent < JsonLdComponent
    def initialize(test_data: nil, **options)
      @test_data = test_data
      super(**options)
    end

    private

    def schema_type
      "TestObject"
    end

    def specific_structure
      return {} unless @test_data

      {
        name: @test_data[:name],
        value: @test_data[:value]
      }
    end
  end

  describe "base component" do
    let(:component) { TestJsonLdComponent.new }

    it "renders a script tag with application/ld+json type" do
      rendered = render_inline(component)

      expect(rendered.css('script[type="application/ld+json"]')).to be_present
    end

    it "generates valid JSON output" do
      rendered = render_inline(component).to_html
      script_content = rendered.match(/<script[^>]*>(.*?)<\/script>/m)[1]

      expect { JSON.parse(script_content) }.not_to raise_error
    end

    it "includes base structure with @context and @type" do
      rendered = render_inline(component).to_html

      expect(rendered).to include('"@context": "https://schema.org"')
      expect(rendered).to include('"@type": "TestObject"')
    end
  end

  describe "with specific data" do
    let(:test_data) { { name: "Test Item", value: 42 } }
    let(:component) { TestJsonLdComponent.new(test_data: test_data) }

    it "merges specific structure with base structure" do
      rendered = render_inline(component).to_html

      expect(rendered).to include('"name": "Test Item"')
      expect(rendered).to include('"value": 42')
      expect(rendered).to include('"@context": "https://schema.org"')
      expect(rendered).to include('"@type": "TestObject"')
    end

    it "stringifies all keys in the final output" do
      rendered = render_inline(component).to_html
      script_content = rendered.match(/<script[^>]*>(.*?)<\/script>/m)[1]
      parsed = JSON.parse(script_content)

      expect(parsed.keys).to all(be_a(String))
      expect(parsed.keys).to include("@context", "@type", "name", "value")
    end
  end

  describe "with nil values" do
    let(:test_data) { { name: "Test", value: nil } }
    let(:component) { TestJsonLdComponent.new(test_data: test_data) }

    it "compacts nil values from output" do
      rendered = render_inline(component).to_html

      expect(rendered).to include('"name": "Test"')
      expect(rendered).not_to include('"value": null')
    end
  end

  describe "error handling" do
    class InvalidJsonLdComponent < JsonLdComponent
      # Does not implement schema_type
    end

    it "raises NotImplementedError when schema_type is not implemented" do
      component = InvalidJsonLdComponent.new

      expect { render_inline(component) }.to raise_error(
        NotImplementedError,
        "Subclasses must implement schema_type method"
      )
    end
  end

  describe "request handling" do
    context "with custom request in options" do
      let(:custom_request) { double("request", original_url: "https://custom.example.com/page") }
      let(:component) { TestJsonLdComponent.new(request: custom_request) }

      it "uses the provided request" do
        allow(component).to receive(:specific_structure).and_return({ url: component.send(:current_url) })
        rendered = render_inline(component).to_html

        expect(rendered).to include('"url": "https://custom.example.com/page"')
      end
    end

    context "without custom request" do
      let(:component) { TestJsonLdComponent.new }

      it "falls back to helpers.request" do
        rendered = render_inline(component).to_html

        # Should render successfully using the default test request
        expect(rendered).to include('"@type": "TestObject"')
      end
    end
  end

  describe "JSON formatting" do
    let(:component) { TestJsonLdComponent.new(test_data: { name: "Test" }) }

    it "pretty prints the JSON for readability" do
      rendered = render_inline(component).to_html
      script_content = rendered.match(/<script[^>]*>(.*?)<\/script>/m)[1]

      # Check for indentation (pretty printing adds newlines and spaces)
      expect(script_content).to include("\n")
      expect(script_content).to include("  ")
    end
  end

  describe "base helper methods" do
    class TestWithBaseMethodsComponent < JsonLdComponent
      def schema_type
        "Article"
      end

      def specific_structure
        {
          headline: "Test Article",
          publisher:,
          mainEntityOfPage: main_entity,
          inLanguage: language,
          datePublished: date_published
        }
      end
    end

    let(:component) { TestWithBaseMethodsComponent.new }

    it "includes default publisher in rendered output" do
      rendered = render_inline(component).to_html

      expect(rendered).to include('"@type": "Organization"')
      expect(rendered).to include('"name": "Hong₿ao"')
      expect(rendered).to include('"logo"')
      expect(rendered).to include('logo')
    end

    it "includes default main_entity in rendered output" do
      rendered = render_inline(component).to_html

      expect(rendered).to include('"@type": "WebPage"')
      expect(rendered).to include('"@id":')
    end

    it "includes default language in rendered output" do
      rendered = render_inline(component).to_html

      expect(rendered).to include('"inLanguage": "en"')
    end

    it "handles nil date_published correctly" do
      rendered = render_inline(component).to_html

      # Since date_published returns nil, it should be compacted out
      expect(rendered).not_to include('"datePublished"')
    end
  end
end

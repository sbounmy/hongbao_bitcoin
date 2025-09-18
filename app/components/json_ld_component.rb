# frozen_string_literal: true

class JsonLdComponent < ApplicationComponent
  def initialize(**options)
    @options = options
  end

  def call
    content_tag(:script, json_ld_content.html_safe, type: "application/ld+json")
  end

  private

  def json_ld_content
    JSON.pretty_generate(structured_data)
  end

  def structured_data
    base_structure.merge(specific_structure).compact.deep_stringify_keys
  end

  def base_structure
    {
      "@context": schema_context,
      "@type": schema_type
    }
  end

  def specific_structure
    {}
  end

  def schema_context
    "https://schema.org"
  end

  def schema_type
    raise NotImplementedError, "Subclasses must implement schema_type method"
  end

  def request
    @options[:request] || helpers.request
  end

  def current_url
    request.original_url
  end

  def publisher
    {
      "@type": "Organization",
      name: "HongBao",
      logo: {
        "@type": "ImageObject",
        url: helpers.image_url("logo.png")
      }
    }
  end

  def main_entity
    {
      "@type": "WebPage",
      "@id": current_url
    }
  end

  def language
    "en"
  end

  def date_published
    nil # Subclasses can override if they have publishable content
  end
end

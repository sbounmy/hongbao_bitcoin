class ElementsController < ApplicationController
  def index
  end


  def get_elements_by_user_id
    # Get user_id from me endpoint
    me_response = me
    unless me_response[:success]
      return me_response
    end

    user_id = me_response[:user_id]
    begin
      api_key = Rails.application.credentials.dig(:leonardo, :api_key)
      unless api_key.present?
        return { success: false, error: "API configuration error" }
      end

      client = LeoAndRuby::Client.new(api_key)
      response = client.get_custom_elements_by_user_id(user_id)

      if response["user_loras"].present?
        elements = response["user_loras"].map do |lora|
          Ai::Element.find_or_create_by!(element_id: lora["id"]) do |element|
            element.title = lora["name"]
            element.weight = 1
          end
        end
        { success: true, count: elements.length }
      else
        { success: false, error: "Invalid API response" }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end


  def me
    begin
      api_key = Rails.application.credentials.dig(:leonardo, :api_key)
      unless api_key.present?
        return { success: false, error: "API configuration error" }
      end

      client = LeoAndRuby::Client.new(api_key)
      response = client.me

      if response["user_details"].present? && response["user_details"].first["user"].present?
        user_details = response["user_details"].first["user"]
        { success: true, user_id: user_details["id"] }
      else
        { success: false, error: "Invalid API response" }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end
end

class SyncLeonardoElementsJob < ApplicationJob
  queue_as :default

  def perform(user_id = nil)
    # Get user_id from Leonardo API if not provided
    unless user_id
      me_response = get_leonardo_user
      return me_response unless me_response[:success]
      user_id = me_response[:user_id]
    end

    sync_elements(user_id)
  end

  private

  def get_leonardo_user
    api_key = Rails.application.credentials.dig(:leonardo, :api_key)
    return { success: false, error: "API configuration error" } unless api_key.present?

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

  def sync_elements(user_id)
    api_key = Rails.application.credentials.dig(:leonardo, :api_key)
    return { success: false, error: "API configuration error" } unless api_key.present?

    client = LeoAndRuby::Client.new(api_key)
    response = client.get_custom_elements_by_user_id(user_id)

    if response["user_loras"].present?
      elements = response["user_loras"].map do |lora|
        Ai::Element.find_or_create_by!(element_id: lora["id"]) do |element|
          element.title = lora["name"]
          element.status = lora["status"]
          element.weight = 1
          element.leonardo_created_at = Time.parse(lora["createdAt"])
          element.leonardo_updated_at = Time.parse(lora["updatedAt"])
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

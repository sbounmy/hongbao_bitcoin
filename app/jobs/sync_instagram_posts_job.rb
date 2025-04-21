class SyncInstagramPostsJob < ApplicationJob
  queue_as :default

  discard_on StandardError # Or specific errors you want to handle without retrying

  def perform(*args)
    Rails.logger.info "Starting Instagram posts sync..."
    service = InstagramService.new
    api_posts = service.fetch_media

    unless api_posts.is_a?(Array)
      Rails.logger.error "Instagram API did not return a valid array. Aborting sync."
      return
    end

    if api_posts.empty? && service.last_response_successful? # Check if API call was ok but returned no posts
      Rails.logger.info "No new posts found on Instagram or API error occurred previously."
      # Consider adding logic here if you want to deactivate old posts not found in the API response
      return
    elsif api_posts.empty? # Implies an API error occurred in fetch_media based on its implementation
       Rails.logger.error "Failed to fetch posts from Instagram API. Aborting sync."
       return # Error already logged by the service
    end


    synced_count = 0
    error_count = 0

    api_posts.each_with_index do |api_post, index|
      # Ensure essential fields are present
      unless api_post['id'] && api_post['media_url'] && api_post['permalink'] && api_post['timestamp']
        Rails.logger.warn "Skipping post due to missing essential data: #{api_post.inspect}"
        error_count += 1
        next
      end

      begin
        # Use instagram_id (original post ID) as the unique identifier
        post = InstagramPost.find_or_initialize_by(instagram_id: api_post['id'])

        post.assign_attributes(
          media_url: api_post['media_url'],
          permalink: api_post['permalink'],
          caption: api_post['caption'],
          published_at: Time.parse(api_post['timestamp']), # Ensure timestamp is parsed
          media_type: api_post['media_type'],
          # Set default position based on fetch order (newest first) or keep existing
          position: post.persisted? ? post.position : (api_posts.length - index),
          active: true # Assume fetched posts should be active
        )

        if post.save
          synced_count += 1
        else
          Rails.logger.error "Failed to save Instagram post #{api_post['id']}: #{post.errors.full_messages.join(', ')}"
          error_count += 1
        end
      rescue ArgumentError => e
         Rails.logger.error "Error parsing timestamp for post #{api_post['id']}: #{e.message}. Data: #{api_post.inspect}"
         error_count += 1
      rescue StandardError => e
        Rails.logger.error "Error processing Instagram post #{api_post['id']}: #{e.message}"
        error_count += 1
      end
    end

    Rails.logger.info "Instagram posts sync finished. Synced: #{synced_count}, Errors: #{error_count}."
  end
end

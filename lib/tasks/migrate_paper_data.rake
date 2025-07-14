namespace :papers do
  desc "Migrate data from Chat and Message models to Paper model"
  task migrate_data: :environment do
    puts "Starting data migration for Papers..."

    Paper.update_all(metadata: "{}")

    Paper.where.not(message_id: nil).find_each do |paper|
      message = paper.message
      next unless message
      chat = message.chat
      next unless chat

      paper.update!(
        costs: message.costs,
        tokens: message.tokens,
        prompt: message.content,
        input_item_ids: chat.input_item_ids,
        input_ids: chat.inputs.map(&:id)
      )

      print "."
    end

    puts "\nData migration for Papers completed."
  end
end

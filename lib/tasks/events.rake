# frozen_string_literal: true

namespace :events do
  desc "Seed events from fixtures"
  task seed: :environment do
    puts "🌱 Seeding events..."
    fixture_file = Rails.root.join("spec/fixtures/inputs.yml")
    data = YAML.load_file(fixture_file)

    events = data.select { |_, attributes| attributes["type"] == "Input::Event" }

    events.each do |key, attributes|
      event = Input::Event.find_or_initialize_by(name: attributes["name"])

      metadata_hash = JSON.parse(attributes["metadata"])
      event.date = metadata_hash["date"]
      event.description = metadata_hash["description"]

      if event.new_record?
        puts "  Creating event: #{attributes['name']}"
      else
        puts "  Updating event: #{attributes['name']}"
      end
      event.save!
    end
    puts "✅ Done seeding #{events.count} events."
  end

  desc "List all events"
  task list: :environment do
    puts "Listing all events..."
    Input::Event.all.each do |event|
      puts "  - Name: #{event.name}, Date: #{event.date}, Description: #{event.description}"
    end
    puts "✅ Found #{Input::Event.count} events."
  end

  desc "Create a new event"
  task :create, [ :name, :date, :description ] => :environment do |t, args|
    puts "Creating a new event..."
    name = args[:name]
    date = args[:date]
    description = args[:description]

    if name.blank? || date.blank?
      puts "❌ Name and date are required."
      puts "Usage: rake 'events:create[name,date,description]'"
      next
    end

    event = Input::Event.new(name: name, date: date, description: description)
    if event.save
      puts "✅ Event '#{name}' created."
    else
      puts "❌ Failed to create event: #{event.errors.full_messages.join(', ')}"
    end
  end

  desc "Update an event"
  task :update, [ :name, :new_name, :date, :description ] => :environment do |t, args|
    puts "Updating an event..."
    name = args[:name]

    event = Input::Event.find_by(name: name)

    if event.nil?
      puts "❌ Event '#{name}' not found."
      next
    end

    event.name = args[:new_name] if args[:new_name].present?
    event.date = args[:date] if args[:date].present?
    event.description = args[:description] if args[:description].present?

    if event.save
      puts "✅ Event '#{name}' updated."
    else
      puts "❌ Failed to update event: #{event.errors.full_messages.join(', ')}"
    end
  end

  desc "Delete an event"
  task :delete, [ :name ] => :environment do |t, args|
    puts "Deleting an event..."
    name = args[:name]

    event = Input::Event.find_by(name: name)

    if event.nil?
      puts "❌ Event '#{name}' not found."
      next
    end

    if event.destroy
      puts "✅ Event '#{name}' deleted."
    else
      puts "❌ Failed to delete event: #{event.errors.full_messages.join(', ')}"
    end
  end
end

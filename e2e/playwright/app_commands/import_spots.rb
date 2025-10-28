# Import Bitcoin spot prices for simulator tests
# Usage: app('import_spots', { limit: 730 }) or app('import_spots') for default 365 days
# Note: Use timecop('2025-10-27') in beforeEach to freeze time before calling this

limit = command_options['limit']&.to_i || 365

SavedHongBao.delete_all
Spot.delete_all
SpotsImportJob.new.perform("usd", limit: limit)

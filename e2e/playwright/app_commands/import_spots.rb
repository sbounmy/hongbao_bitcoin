# Import Bitcoin spot prices for simulator tests
# Uses activerecord_fixtures to load pre-seeded spot data
# Note: Use timecop('2025-10-27') in beforeEach to freeze time before calling this

SavedHongBao.delete_all
Spot.delete_all
SpotsImportJob.new.perform("usd", seed: true)

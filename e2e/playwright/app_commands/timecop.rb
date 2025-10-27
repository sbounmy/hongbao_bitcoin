# Timecop helper for freezing/unfreezing time in E2E tests
# Usage from Playwright:
#   await timecop('2025-10-27')           // freeze to date
#   await timecop.freeze('2025-10-27')    // freeze to date
#   await timecop.travel('2025-10-27')    // travel to date
#   await timecop.return()                // unfreeze time

action = command_options['action'] || 'freeze'
date_str = command_options['date']


case action
when 'freeze'
  if date_str
    date = Date.parse(date_str)
    Timecop.freeze(date)
  else
    raise ArgumentError, "Date is required for freeze action"
  end
when 'travel'
  if date_str
    date = Date.parse(date_str)
    Timecop.travel(date)
  else
    raise ArgumentError, "Date is required for travel action"
  end
when 'return'
  Timecop.return
else
  raise ArgumentError, "Unknown action: #{action}"
end

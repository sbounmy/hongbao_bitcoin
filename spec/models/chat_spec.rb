require 'rails_helper'

RSpec.describe Chat, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:bundle) }
  it { should have_many(:messages).dependent(:destroy) }
end

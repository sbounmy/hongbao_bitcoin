require 'rails_helper'

RSpec.describe Identity do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should validate_presence_of(:provider_name) }
    it { should validate_presence_of(:provider_uid) }
    it { should validate_uniqueness_of(:provider_uid).scoped_to(:provider_name) }
  end
end

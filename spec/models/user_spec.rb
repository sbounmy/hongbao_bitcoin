require 'rails_helper'

RSpec.describe User, type: :model do
  # Add model specs later as needed

  describe 'on creation' do
    let(:user) { build(:user) }

    context 'when user is created' do
      it 'automatically adds welcome tokens' do
        expect do
          user.save!
        end.to change(user.tokens, :count).by(1)

        token = user.tokens.last
        expect(token.quantity).to eq(5)
        expect(token.description).to eq('Welcome tokens')
      end

      it 'does not add tokens on save' do
        user.save!
        expect do
          user.save!
        end.not_to change(user.tokens, :count)
      end
    end
  end
end

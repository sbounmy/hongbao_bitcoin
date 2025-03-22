require 'rails_helper'

RSpec.describe Ai::Images::Create, type: :service do
  # Note: Before running these tests for the first time, you need to:
  # 1. Make sure the webmock gem is installed
  # 2. Record the VCR cassettes by running the tests with real API calls

  describe '#call' do
    # Use fixtures instead of FactoryBot
    fixtures :users, :ai_themes, :ai_elements, :ai_elements_themes

    let(:user) { users(:john) }
    let(:theme) { ai_themes(:birthday) }
    let(:element) { ai_elements(:birthday_element) }
    let(:params) { { occasion: 'birthday' } }

    subject(:service) { described_class }

    it 'creates a new image record', :vcr do
      VCR.use_cassette('leonardo_ai/birthday_image_create') do
        expect { service.call(params: params, user: user) }.to change(Ai::Image, :count).by(1)
      end
    end

    it 'sets the correct attributes on the image', :vcr do
      VCR.use_cassette('leonardo_ai/birthday_image_attributes') do
        image = service.call(params: params, user: user).payload

        expect(image).to have_attributes(
          prompt: 'A birthday bitcoin themed bill add text public address and private key',
          status: 'processing',
          user: user,
          request_theme_id: theme.id
        )
        # We don't assert on the exact external_id since it will come from the real API response
        expect(image.external_id).to be_present
      end
    end

    context 'when theme is not found' do
      let(:params) { { occasion: 'non_existent' } }

      it 'raises an error' do
        expect { service.call(params: params, user: user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with different occasions' do
      let(:params) { { occasion: 'wedding' } }

      it 'uses the appropriate theme', :vcr do
        VCR.use_cassette('leonardo_ai/wedding_image_create') do
          # Use the wedding theme from fixtures
          wedding_theme = ai_themes(:wedding)

          image = service.call(params: params, user: user).payload
          expect(image.request_theme_id).to eq(wedding_theme.id)
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Ai::ImageGpts::Create do
  fixtures :users, :papers

  let(:user) { users(:john) }
  let(:paper) { papers(:dollar) }
  let(:service) { described_class.new }
  let(:sample_image_data) { fixture_file_upload('spec/fixtures/files/satoshi.jpg', 'image/jpeg') }
  let(:params) do
    {
      ai_theme_id: ai_themes(:euro).id,
      image: sample_image_data,
      ai_style_ids: [ ai_styles(:ghibli).id, ai_styles(:simpson).id ]
    }
  end

  describe '#call' do
    context 'when successful', vcr: { cassette_name: 'ai/images_gpt/create/success' } do
      it 'processes the image and updates the paper' do
        expect do
          service.call(params:, user:)
        end.to change(Paper, :count).by(3)

        expect(result).to eq(paper)
        expect(paper.image_front).to be_attached
        expect(paper.image_front.content_type).to eq('image/png')
        expect(paper.image_front.filename.to_s).to match(/generated_front_\d+\.png/)
      end
    end

    context 'when theme is not found' do
      let(:params) { { ai_theme_id: 'non_existent' } }

      it 'raises an error' do
        expect {
          service.call(params: params, user: user)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when image generation fails', vcr: { cassette_name: 'ai/images_gpt/create/failure' } do
      it 'raises an error with appropriate message' do
        expect {
          service.call(params: params, user: user)
        }.to raise_error(Ai::ImageGpts::Create::Error, /Failed to generate image/)
      end
    end

    context 'when API returns invalid response', vcr: { cassette_name: 'ai/images_gpt/create/invalid_response' } do
      it 'raises an error with appropriate message' do
        expect {
          service.call(params: params, user: user)
        }.to raise_error(Ai::ImageGpts::Create::Error, /Failed to generate image/)
      end
    end
  end
end

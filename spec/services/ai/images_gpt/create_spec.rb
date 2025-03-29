require 'rails_helper'

RSpec.describe Ai::ImagesGpt::Create do
  fixtures :users, :papers

  let(:user) { users(:john) }
  let(:paper) { papers(:one) }
  let(:service) { described_class.new }
  let(:sample_image_data) { fixture_file_upload('spec/fixtures/files/satoshi.jpg', 'image/jpeg') }
  let(:params) do
    {
      paper_id: paper.id,
      image: sample_image_data
    }
  end

  describe '#call' do
    context 'when successful', vcr: { cassette_name: 'ai/images_gpt/create/success' } do
      it 'processes the image and updates the paper' do
        result = service.call(params:, user:)

        expect(result).to eq(paper)
        expect(paper.image_front).to be_attached
        expect(paper.image_front.content_type).to eq('image/png')
        expect(paper.image_front.filename.to_s).to match(/generated_front_\d+\.png/)
      end
    end

    context 'when paper is not found' do
      let(:params) { { paper_id: 'non_existent' } }

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
        }.to raise_error(Ai::ImagesGpt::Create::Error, /Failed to generate image/)
      end
    end

    context 'when API returns invalid response', vcr: { cassette_name: 'ai/images_gpt/create/invalid_response' } do
      it 'raises an error with appropriate message' do
        expect {
          service.call(params: params, user: user)
        }.to raise_error(Ai::ImagesGpt::Create::Error, /Failed to generate image/)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Bundles::Create do
  fixtures :users, :papers

  let(:user) { users(:john) }
  let(:paper) { papers(:dollar) }
  let(:ghibli) { inputs(:ghibli) }
  let(:simpson) { inputs(:simpson) }
  let(:dollar) { inputs(:dollar) }
  let(:user_upload) { inputs(:user) }

  let(:service) { described_class }
  let(:sample_image_data) { fixture_file_upload('spec/fixtures/files/satoshi.jpg', 'image/jpeg') }
  let(:params) do
    {
      input_items_attributes: [
        {
          input_id: ghibli.id
        },
        {
          input_id: simpson.id
        },
        {
          input_id: dollar.id
        },
        {
          image: sample_image_data,
          input_id: user_upload.id
        }
      ]
    }
  end

  describe '#call' do
    context 'when successful' do
      it 'creates a new bundle' do
        expect do
          service.call(params:, user:)
        end.to change(Bundle, :count).by(1)

        expect(Bundle.last).to have_attributes(
          user:,
          theme: dollar,
          styles: [ ghibli, simpson ]
        )
      end

      it 'creates a new paper per style' do
        expect do
          service.call(params:, user:)
        end.to change(Paper, :count).by(2)

        bundle = Bundle.last
        expect(bundle.papers.first).to have_attributes(
          user:,
          bundle:
        )
        expect(bundle.papers.first.inputs).to include(dollar, ghibli, user_upload)

        expect(bundle.papers.last).to have_attributes(
          user:,
          bundle:
        )
        expect(bundle.papers.last.inputs).to include(dollar, simpson, user_upload)
      end

      it 'process a new job per paper' do
        expect do
          service.call(params:, user:)
        end.to have_enqueued_job(ProcessPaperJob).twice
      end
    end

    context 'when theme is not found' do
      before do
        dollar.destroy
      end

      it 'raises an error' do
        expect {
          service.call(params: params, user: user)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when image generation fails', vcr: { cassette_name: 'ai/images_gpt/create/failure' } do
      it 'raises an error with appropriate message' do
        skip 'todo when rubyLLM'
        expect {
          service.call(params: params, user: user)
        }.to raise_error(ApplicationService::ErrorService, /Failed to generate image/)
      end
    end

    context 'when API returns invalid response', vcr: { cassette_name: 'ai/images_gpt/create/invalid_response' } do
      it 'raises an error with appropriate message' do
        skip 'todo when rubyLLM'
        expect {
          service.call(params: params, user: user)
        }.to raise_error(ApplicationService::ErrorService, /Failed to generate image/)
      end
    end
  end
end

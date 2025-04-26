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

      it 'creates a new chat per style' do
        expect do
          service.call(params:, user:)
        end.to change(Chat, :count).by(2)

        bundle = Bundle.last
        expect(bundle.chats.first).to have_attributes(
          user:,
          bundle:,
          input_item_ids: [ dollar.id, ghibli.id, user_upload.id ]
        )
        expect(bundle.chats.last).to have_attributes(
          user:,
          bundle:,
          input_item_ids: [ dollar.id, simpson.id, user_upload.id ]
        )
      end

      it 'creates a new paper per chat' do
        expect do
          service.call(params:, user:)
        end.to change(Paper, :count).by(2)

        expect(Paper.last.ai_style_id).to eq(ai_styles(:simpson).id)
        expect(Paper.last.ai_theme_id).to eq(ai_themes(:euro).id)
        expect(Paper.last.image_front).to be_attached
        expect(Paper.last.image_front.content_type).to eq('image/jpeg')
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

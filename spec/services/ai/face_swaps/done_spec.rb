require 'rails_helper'
require 'open-uri'

RSpec.describe Ai::FaceSwaps::Done do
  let(:user) { users(:one) }
  let(:paper) { papers(:one) }
  let(:face_swap) { ai_face_swaps(:one) }
  let(:result_image_url) { "https://example.com/face_swap.webp" }

  let(:valid_params) do
    {
      success: 1,
      task_id: face_swap.external_id,
      result_image: result_image_url,
      type: 1
    }
  end

  before do
    # Stub URI.open to avoid actual HTTP requests
    allow(URI).to receive(:open).with(result_image_url).and_return(
      fixture_file_upload('spec/fixtures/files/test.png', 'image/png')
    )
  end

  describe '#call' do
    context 'when successful' do
      it 'creates a child paper' do
        expect {
          described_class.call(valid_params)
        }.to change(Paper, :count).by(1)

        child_paper = Paper.last
        expect(child_paper.parent).to eq(paper)
        expect(child_paper.name).to eq("#{paper.name} (Face Swap)")
        expect(child_paper.user).to eq(user)
      end

      it 'marks face swap as done' do
        described_class.call(valid_params)
        expect(face_swap.reload).to be_completed
      end

      it 'returns success response' do
        result = described_class.call(valid_params)
        expect(result).to be_success
        expect(result.payload).to eq(face_swap)
      end
    end

    context 'when face swap failed' do
      let(:failed_params) { valid_params.merge(success: 0) }

      it 'returns failure response' do
        expect {
          described_class.call(failed_params)
        }.to raise_error(StandardError, "Face swap failed")
      end
    end

    context 'when face swap not found' do
      let(:invalid_params) { valid_params.merge(task_id: 'invalid_task_id') }

      it 'returns failure response' do
        expect {
          described_class.call(invalid_params)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when error occurs during image attachment' do
      before do
        allow(URI).to receive(:open).and_raise(SocketError.new('Failed to open TCP connection'))
      end

      it 'returns failure response' do
        expect {
          described_class.call(valid_params)
        }.to raise_error(SocketError)
      end
    end
  end
end

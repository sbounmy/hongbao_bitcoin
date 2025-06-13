require 'rails_helper'

RSpec.describe ImageGapCorrectorService do
  let(:fixtures_path) { Rails.root.join('spec/fixtures/images') }

  describe '#find_red_line' do
    context 'with longer red line' do
      let(:image_path) { fixtures_path.join('longer_red_line.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'detects red line at y=488' do
        line_y = service.find_red_line
        expect(line_y).to eq(488)
      end
    end

    context 'with no red line' do
      let(:image_path) { fixtures_path.join('no_red_line.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'returns nil' do
        line_y = service.find_red_line
        expect(line_y).to be_nil
      end
    end

    context 'with normal red line' do
      let(:image_path) { fixtures_path.join('normal_red_line.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'detects red line at y=488' do
        line_y = service.find_red_line
        expect(line_y).to eq(488)
      end
    end

    context 'with 2px high red line' do
      let(:image_path) { fixtures_path.join('red_line_2px_high.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'detects thin red line at y=507' do
        line_y = service.find_red_line
        expect(line_y).to eq(507)
      end
    end

    context 'with red line with gap' do
      let(:image_path) { fixtures_path.join('red_line_with_gap.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'detects red line despite gaps at y=488' do
        line_y = service.find_red_line
        expect(line_y).to eq(488)
      end
    end

    context 'with red line with narrow gap' do
      let(:image_path) { fixtures_path.join('red_line_with_narrow_gap.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'detects red line with narrow gaps at y=488' do
        line_y = service.find_red_line
        expect(line_y).to eq(488)
      end
    end

    context 'with red line with narrower gap' do
      let(:image_path) { fixtures_path.join('red_line_with_narrower_gap.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'detects red line with narrower gaps at y=488' do
        line_y = service.find_red_line
        expect(line_y).to eq(488)
      end
    end

    context 'with small red line' do
      let(:image_path) { fixtures_path.join('small_red_line.png') }
      let(:service) { ImageGapCorrectorService.new(image_path) }

      it 'detects small red line at y=488' do
        line_y = service.find_red_line
        expect(line_y).to eq(488)
      end
    end
  end

  describe '.correct_gaps' do
    context 'class method integration' do
      let(:image_blob) { File.binread(fixtures_path.join('normal_red_line.png')) }

      it 'returns a blob when processing image' do
        result = ImageGapCorrectorService.correct_gaps(image_blob)

        expect(result).to be_a(String)
        expect(result.length).to be > 0
        expect(result).not_to eq(image_blob)
      end
    end
  end
end

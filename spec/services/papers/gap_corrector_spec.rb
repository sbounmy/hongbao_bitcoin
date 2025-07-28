require 'rails_helper'

RSpec.describe Papers::GapCorrector do
  let(:fixtures_path) { Rails.root.join('spec/fixtures/images') }

  describe '#find_red_line' do
    context 'with longer red line' do
      let(:image_blob) { File.binread(fixtures_path.join('longer_red_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects red line at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with no red line' do
      let(:image_blob) { File.binread(fixtures_path.join('no_red_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'returns nil' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to be_nil
      end
    end

    context 'with normal red line' do
      let(:image_blob) { File.binread(fixtures_path.join('normal_red_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects red line at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with 2px high red line' do
      let(:image_blob) { File.binread(fixtures_path.join('red_line_2px_high.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects thin red line at y=507' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(507)
      end
    end

    context 'with red line with gap' do
      let(:image_blob) { File.binread(fixtures_path.join('red_line_with_gap.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects red line despite gaps at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with red line with narrow gap' do
      let(:image_blob) { File.binread(fixtures_path.join('red_line_with_narrow_gap.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects red line with narrow gaps at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with red line with narrower gap' do
      let(:image_blob) { File.binread(fixtures_path.join('red_line_with_narrower_gap.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects red line with narrower gaps at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with small red line' do
      let(:image_blob) { File.binread(fixtures_path.join('small_red_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects small red line at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with darker red line' do
      let(:image_blob) { File.binread(fixtures_path.join('darker_red_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects darker red line at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_red_line)
        expect(line_y).to eq(455)
      end
    end
  end

  describe '.call' do
    context 'class method integration' do
      let(:image_blob) { File.binread(fixtures_path.join('normal_red_line.png')) }

      it 'returns processed blob directly' do
        result = Papers::GapCorrector.call(image_blob)

        expect(result).to be_a(String)
        expect(result.length).to be > 0
        expect(result).not_to eq(image_blob)
      end
    end

    context 'when processing fails' do
      let(:invalid_blob) { "not_an_image" }

      it 'returns original blob when error occurs' do
        result = Papers::GapCorrector.call(invalid_blob)

        expect(result).to eq(invalid_blob)
      end
    end

    context 'when no red line found' do
      let(:image_blob) { File.binread(fixtures_path.join('no_red_line.png')) }

      it 'returns original blob' do
        result = Papers::GapCorrector.call(image_blob)

        expect(result).to eq(image_blob)
      end
    end
  end

  private

  def setup_service_for_testing(service, image_blob)
    temp_file = Tempfile.new([ 'test', '.png' ])
    temp_file.binmode
    temp_file.write(image_blob)
    temp_file.close

    image = ChunkyPNG::Image.from_file(temp_file.path)
    service.instance_variable_set(:@image, image)
    service.instance_variable_set(:@width, image.width)
    service.instance_variable_set(:@height, image.height)

    # Cleanup
    temp_file.unlink
  end
end

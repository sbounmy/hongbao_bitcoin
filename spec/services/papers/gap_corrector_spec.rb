require 'rails_helper'

RSpec.describe Papers::GapCorrector do
  let(:fixtures_path) { Rails.root.join('spec/fixtures/images') }

  describe '#find_green_line' do
    context 'with longer green line' do
      let(:image_blob) { File.binread(fixtures_path.join('longer_green_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects green line at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with no green line' do
      let(:image_blob) { File.binread(fixtures_path.join('no_green_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'returns nil' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to be_nil
      end
    end

    context 'with normal green line' do
      let(:image_blob) { File.binread(fixtures_path.join('normal_green_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects green line at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with 2px high green line' do
      let(:image_blob) { File.binread(fixtures_path.join('green_line_2px_high.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects thin green line at y=489' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(489)
      end
    end

    context 'with green line with gap' do
      let(:image_blob) { File.binread(fixtures_path.join('green_line_with_gap.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects green line despite gaps at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with green line with narrow gap' do
      let(:image_blob) { File.binread(fixtures_path.join('green_line_with_narrow_gap.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects green line with narrow gaps at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with green line with narrower gap' do
      let(:image_blob) { File.binread(fixtures_path.join('green_line_with_narrower_gap.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects green line with narrower gaps at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(488)
      end
    end

    context 'with small green line' do
      let(:image_blob) { File.binread(fixtures_path.join('small_green_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects small green line at y=489' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(489)
      end
    end

    context 'with darker green line' do
      let(:image_blob) { File.binread(fixtures_path.join('darker_green_line.png')) }
      let(:service) { Papers::GapCorrector.new }

      it 'detects darker green line at y=488' do
        setup_service_for_testing(service, image_blob)

        line_y = service.send(:find_green_line)
        expect(line_y).to eq(nil)
      end
    end
  end

  describe '.call' do
    context 'class method integration' do
      let(:image_blob) { File.binread(fixtures_path.join('normal_green_line.png')) }

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

    context 'when no green line found' do
      let(:image_blob) { File.binread(fixtures_path.join('no_green_line.png')) }

      it 'returns upper half of image' do
        result = Papers::GapCorrector.call(image_blob)

        # Should return processed image, not original
        expect(result).not_to eq(image_blob)
        expect(result).to be_a(String)
        expect(result.length).to be > 0

        # Verify it's a valid PNG
        expect(result[0..7].force_encoding('ASCII-8BIT')).to eq("\x89PNG\r\n\x1A\n".force_encoding('ASCII-8BIT'))
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

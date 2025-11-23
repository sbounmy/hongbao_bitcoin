class Frame
  TYPES = {
    'landscape' => {
      dimensions: [150, 75],
      rotation_front: '',
      rotation_back: 'transform rotate-180',
      fold_line: 'border-t-2',
      layout_direction: 'flex-col',  # Stack vertically for landscape
      layout_classes: 'items-stretch w-[150mm]'
    },
    'portrait' => {
      dimensions: [75, 113],  # Maintains 2:3 aspect ratio (1024x1536)
      rotation_front: '',
      rotation_back: '',
      fold_line: 'border-l-2',
      layout_direction: 'flex-row',  # Stack horizontally for portrait
      layout_classes: 'items-stretch min-h-[113mm]'  # Ensure full height with correct ratio
    }
  }.freeze

  attr_reader :type

  def initialize(type = 'landscape')
    @type = type
  end

  def config
    TYPES[@type] || TYPES['landscape']
  end

  def dimensions
    config[:dimensions]
  end

  def width
    dimensions[0]
  end

  def height
    dimensions[1]
  end

  def aspect_ratio
    "#{width}/#{height}"
  end

  def css_classes
    "w-[#{width}mm] h-[#{height}mm]"
  end

  def rotation_front
    config[:rotation_front]
  end

  def rotation_back
    config[:rotation_back]
  end

  def fold_line
    config[:fold_line]
  end

  def layout_direction
    config[:layout_direction] || 'flex-col'
  end

  def layout_classes
    config[:layout_classes] || 'items-center'
  end

  def portrait?
    @type == 'portrait'
  end

  def landscape?
    @type == 'landscape'
  end

  # Convert mm to pixels for canvas (96 DPI: 1mm ≈ 3.7795 pixels)
  MM_TO_PX = 3.7795

  def canvas_width_px
    (width * MM_TO_PX).round
  end

  def canvas_height_px
    (height * MM_TO_PX).round
  end

  # Get canvas dimensions in pixels
  # No rotation check needed - dimensions are already correct in the frame definition
  def canvas_dimensions
    { width: canvas_width_px, height: canvas_height_px }
  end
end
module ThemeHelper
  # DaisyUI semantic color classes that automatically work with themes
  
  # Text color classes
  def text_primary_classes
    "text-base-content"
  end
  
  def text_secondary_classes
    "text-base-content/70"
  end
  
  def text_muted_classes
    "text-base-content/50"
  end
  
  # Background classes
  def bg_primary_classes
    "bg-base-100"
  end
  
  def bg_secondary_classes
    "bg-base-200"
  end
  
  def bg_card_classes
    "bg-base-100"
  end
  
  # Border classes
  def border_primary_classes
    "border-base-300"
  end
  
  # Component-specific classes
  def btn_primary_classes
    "btn btn-primary"
  end
  
  def btn_secondary_classes
    "btn btn-secondary"
  end
  
  def link_classes
    "link link-primary"
  end
end
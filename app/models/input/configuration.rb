class Input::Configuration < Input
  POSITION = 0  # Highest priority (lowest number)

  validates :prompt, presence: true

  # Get or create the singleton configuration
  def self.instance
    first_or_create!(
      name: "AI Base Configuration",
      slug: "ai-base-configuration",
      prompt: "..."
    )
  end
end

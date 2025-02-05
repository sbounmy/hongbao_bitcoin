class Step
  attr_reader :name, :icon, :position

  def initialize(name:, icon:, position:)
    @name = name
    @icon = icon
    @position = position
  end

  def fullname
    "#{position}. #{name}"
  end

  def self.for_new
    [
      new(
        name: "Design",
        icon: "photo",
        position: 1
      ),
      new(
        name: "Print",
        icon: "printer",
        position: 2
      ),
      new(
        name: "Top up",
        icon: "credit-card",
        position: 3
      )
    ]
  end

  def self.for_show
    [
      new(
        name: "Balance",
        icon: "chart-bar",
        position: 1
      ),
      new(
        name: "Private key",
        icon: "key",
        position: 2
      ),
      new(
        name: "Destination",
        icon: "paper-airplane",
        position: 3
      ),
      new(
        name: "Complete",
        icon: "check-circle",
        position: 4
      )
    ]
  end
end

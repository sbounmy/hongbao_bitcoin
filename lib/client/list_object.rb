module Client
  class ListObject < Object
    include Enumerable

    def each(&block)
      data.each(&block)
    end

    def [](index)
      data[index]
    end

    def data
      @attributes["data"] || @attributes["results"] || []
    end

    def total_count
      @attributes["total_count"] || @attributes["count"] || data.size
    end

    def empty?
      data.empty?
    end

    def to_a
      data
    end
  end
end

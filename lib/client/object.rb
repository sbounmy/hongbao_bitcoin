module Client
  class Object
    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = {}
      refresh_from(attributes)
    end

    def refresh_from(attributes)
      attributes.each do |key, value|
        @attributes[key.to_s] = convert_to_client_object(value)
      end
      self
    end

    def to_s
      pretty_attributes = JSON.pretty_generate(@attributes)
      "#<#{self.class}:#{object_id} #{pretty_attributes}>"
    end

    def inspect
      to_s
    end

    def [](key)
      @attributes[key.to_s]
    end

    def method_missing(name, *args, &block)
      if name.to_s.end_with?("=")
        attribute_name = name.to_s[0...-1]
        @attributes[attribute_name] = args[0]
      elsif @attributes.key?(name.to_s)
        @attributes[name.to_s]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @attributes.key?(name.to_s) || name.to_s.end_with?("=") || super
    end

    private

    def convert_to_client_object(value)
      case value
      when Hash
        Client::Object.new(value)
      when Array
        value.map { |v| convert_to_client_object(v) }
      else
        value
      end
    end
  end
end

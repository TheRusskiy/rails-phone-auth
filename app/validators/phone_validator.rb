class PhoneValidator
  class << self
    def clean(value)
      value ? value.gsub(/[()\s-]/, '') : value
    end

    def valid?(value)
      !!(clean(value) =~ /^\d{10}$/i)
    end
  end
end

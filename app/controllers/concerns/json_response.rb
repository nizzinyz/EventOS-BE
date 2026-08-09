module JsonResponse
  extend ActiveSupport::Concern

  private

  DECIMAL_FIELDS = %w[
    price_from
    rating
  ].freeze

  def camelize_json(resource)
    normalize_json(resource.as_json)
  end

  def normalize_json(value)
    case value
    when Array
      value.map { |item| normalize_json(item) }

    when Hash
      value.each_with_object({}) do |(key, item), result|
        normalized_value =
          if DECIMAL_FIELDS.include?(key.to_s) && !item.nil?
            item.to_f
          else
            normalize_json(item)
          end

        result[key.to_s.camelize(:lower)] = normalized_value
      end

    else
      value
    end
  end
end
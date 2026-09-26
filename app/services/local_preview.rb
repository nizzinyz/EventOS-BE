module LocalPreview
  def self.enabled?(environment: Rails.env)
    %w[development test].include?(environment.to_s) && Rails.configuration.x.local_preview == true
  end
end

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development allow the local frontend.
    # In production set CORS_ALLOWED_ORIGINS to a comma-separated list of
    # allowed origins, e.g. "https://app.example.com,https://www.example.com"
    allowed = ENV.fetch("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173,http://localhost:8081,http://localhost:19006")
    origins allowed.split(",").map(&:strip)

    resource "*",
      headers: :any,
      expose:  ["Authorization"],   # expose JWT token header to the client
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

# Never enables preview checkout or bypasses confirmation in production.
Rails.application.config.x.local_preview = (Rails.env.development? || Rails.env.test?) && ENV.fetch("LOCAL_PREVIEW", Rails.env.development? ? "true" : "false") == "true"

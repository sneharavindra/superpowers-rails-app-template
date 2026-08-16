Fosm.configure do |config|
  # FOSM controllers inherit ApplicationController, which already enforces
  # require_authentication globally — no duplicate auth needed here.
  config.base_controller = "ApplicationController"

  # TalkyForm uses CurrentAttributes, not a current_user helper method.
  config.current_user_method = -> { Current.user }

  # Only superadmins can access /fosm/admin.
  # main_app helper is required here because this lambda runs inside the mounted engine context.
  config.admin_authorize = -> { redirect_to main_app.root_path unless Current.user&.superadmin? }

  # app_authorize is a no-op: ApplicationController already enforces auth.
  config.app_authorize = ->(_level) {}

  config.admin_layout = "application"
  config.app_layout   = "application"

  # :async uses Solid Queue (already running inside Puma) for non-blocking log writes.
  config.transition_log_strategy = :async
end

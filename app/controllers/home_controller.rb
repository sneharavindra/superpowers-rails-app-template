class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      redirect_to dashboard_path
    else
      redirect_to new_session_path
    end
  end
end

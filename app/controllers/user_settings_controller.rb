class UserSettingsController < ApplicationController
  layout "authenticated"

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(user_settings_params)
      redirect_to edit_user_settings_path, notice: "Settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_settings_params
    params.require(:user).permit(:email_address)
  end
end

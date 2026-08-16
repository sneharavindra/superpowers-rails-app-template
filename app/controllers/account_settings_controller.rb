class AccountSettingsController < ApplicationController
  layout "authenticated"

  def edit
    @account = Current.user.account
  end

  def update
    @account = Current.user.account

    if @account.update(account_settings_params)
      redirect_to edit_account_settings_path, notice: "Settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_settings_params
    params.require(:account).permit(:name)
  end
end

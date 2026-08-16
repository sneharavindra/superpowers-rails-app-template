class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    first_name = params[:name].to_s.split(" ", 2).first.presence || params[:name].to_s

    ActiveRecord::Base.transaction do
      @account = Account.create!(name: "#{first_name}'s Org")
      @user = User.create!(
        account: @account,
        email_address: params[:email_address],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )
    end

    start_new_session_for @user
    redirect_to dashboard_path
  rescue ActiveRecord::RecordInvalid => e
    @user ||= User.new(email_address: params[:email_address])
    @user.errors.add(:base, e.message) if @user.errors.empty?
    render :new, status: :unprocessable_entity
  end
end

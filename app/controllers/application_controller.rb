class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :monthly_income, :currency])
  end

  private

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def record_not_found
    redirect_to root_path, alert: 'Registro nao encontrado.'
  end
end

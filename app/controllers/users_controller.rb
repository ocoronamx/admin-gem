class UsersController < ApplicationController
  filterable_by email: :by_email

  before_action :set_user, only: %i[ edit update toggle_active ]

  def index
    authorize User
    scope = apply_filters(policy_scope(User)).order(:email_address)
    @pagy, @users = pagy(:offset, scope)
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      redirect_to users_path, notice: "Usuario creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    # Nadie cambia su propio rol desde acá, ni siquiera un admin — la vista ya
    # no muestra el <select> para ese caso, esto es la segunda capa.
    attrs = @user == Current.user ? user_params.except(:role_id) : user_params

    if @user.update(attrs)
      redirect_to users_path, notice: "Usuario actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_active
    authorize @user

    if @user.active?
      @user.update!(deactivated_at: Time.current)
      @user.sessions.destroy_all
      notice = "Usuario desactivado."
    else
      @user.update!(deactivated_at: nil)
      notice = "Usuario reactivado."
    end

    redirect_to users_path, notice: notice
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :role_id)
  end
end

# Modelo de demostración, exclusivo para /styleguide (Setup 9). No se persiste
# ni tiene tabla — existe solo para mostrar AdminFormBuilder con un objeto
# real, incluyendo un error simulado en :email para ver el validator-hint
# en rojo (ver #initialize).
class StyleguideForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :bio, :string
  attribute :birthdate, :date
  attribute :country, :string
  attribute :tags
  attribute :newsletter, :boolean, default: false

  def initialize(...)
    super
    errors.add(:email, "ya está en uso") # fuerza el estado de error en la demo
  end
end

# frozen_string_literal: true

class ApplicationPolicy
  include PermissionResource

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    permitted?(:view)
  end

  def show?
    permitted?(:view)
  end

  def create?
    permitted?(:manage)
  end

  def new?
    create?
  end

  def update?
    permitted?(:manage)
  end

  def edit?
    update?
  end

  def destroy?
    permitted?(:manage)
  end

  class Scope
    include PermissionResource

    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      permitted?(:view) ? scope.all : scope.none
    end
  end
end

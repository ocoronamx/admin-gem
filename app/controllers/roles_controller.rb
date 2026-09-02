class RolesController < ApplicationController
  filterable_by name: :by_name, key: :by_key

  def index
    scope = apply_filters(policy_scope(Role)).order(:name)
    @pagy, @roles = pagy(:offset, scope)
  end
end
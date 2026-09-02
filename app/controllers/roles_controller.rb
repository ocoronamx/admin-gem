class RolesController < ApplicationController
  filterable_by :by_name, :by_key

  def index
    scope = apply_filters(policy_scope(Role)).order(:name)
    @pagy, @roles = pagy(:offset, scope)
  end
end
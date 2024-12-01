class DemosController < ApplicationController
  layout :set_layout, only: [:landing, :login]
  def landing
  end

  def login
  end

  def dashboard
    init_breadcrumb('demo.dashboard')
  end

  def index
    init_breadcrumb('demo.index')
    add_breadcrumb(demos_index_path, 'demo.index')

    @list = [
      { id: '000', name: 'Alexander Pierce', email: 'root@mail.com', role: 'admin' },
      { id: '001', name: 'Lucy Johnson', email: 'lucyjhonson@mail.com', role: 'admin' },
      { id: '002', name: 'John Anderson', email: 'jhonanderson@mail.com', role: 'employee' },
      { id: '003', name: 'Sophie Turner', email: 'sophieturner@mail.com', role: 'technical' } ]
  end

  def form
    init_breadcrumb('demo.form')
    add_breadcrumb(demos_index_path, 'demo.form')
  end

  private

  def set_layout
    case action_name
    when 'login'
      'login'
    when 'landing'
      'outside'
    else
      'application' # Default layout
    end
  end
end

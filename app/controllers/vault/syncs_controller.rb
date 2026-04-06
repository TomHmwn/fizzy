class Vault::SyncsController < ApplicationController
  before_action :ensure_admin

  def create
    Vault::SyncJob.perform_later(Current.account, Current.user, note_params)
    head :ok
  end

  private
    def note_params
      params.expect(note: [ :name, sections: [ [ :name, todos: [ [ :text, :done, steps: [ [ :text, :done ] ] ] ] ] ] ]).to_h
    end
end

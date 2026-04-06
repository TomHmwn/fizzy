class Vault::SyncJob < ApplicationJob
  queue_as :default

  def perform(account, user, note_data)
    Current.account = account
    Current.user    = user

    Vault::NoteSync.new(account, user).call(note_data)
  end
end

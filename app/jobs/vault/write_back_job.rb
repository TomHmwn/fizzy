class Vault::WriteBackJob < ApplicationJob
  queue_as :default

  discard_on Vault::Git::Error

  def perform(action, card)
    Vault::CardWriteBack.new.public_send(action, card)
  end
end

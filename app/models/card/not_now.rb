class Card::NotNow < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :card, class_name: "::Card", touch: true
  belongs_to :user, optional: true

  after_create_commit -> { Vault::WriteBackJob.perform_later(:postpone, card) }
end

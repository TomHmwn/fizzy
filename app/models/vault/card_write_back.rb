# Writes a card state change back to the vault markdown file.
# Pulls latest vault, updates the todo line, commits and pushes.
#
# Requires VAULT_PATH to be set in the environment.
# If unset, all operations are no-ops (graceful degradation).
#
# Usage:
#   Vault::CardWriteBack.new.close(card)
#   Vault::CardWriteBack.new.postpone(card)
class Vault::CardWriteBack
  def initialize(vault_path: ENV["VAULT_PATH"])
    @vault_path = vault_path
  end

  def close(card)
    write_back(card, to_section: "Done", done: true, verb: "Close")
  end

  def postpone(card)
    write_back(card, to_section: "Not Now", done: false, verb: "Postpone")
  end

  private
    def write_back(card, to_section:, done:, verb:)
      return unless @vault_path.present?

      note = Vault::ChildNote.find(card.board.name, @vault_path)
      return unless note

      git = Vault::Git.new(@vault_path)
      git.pull

      note.writer.move_todo(to_section: to_section, text: card.title, done: done)
      git.commit_and_push("#{verb}: #{card.title.truncate(72)}")
    end
end

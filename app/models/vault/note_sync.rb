# Rebuilds a Fizzy board from a vault note payload.
# Destructive per board — existing cards are wiped and rebuilt from the payload.
# Vault wins always.
class Vault::NoteSync
  NATIVE_SECTIONS = %w[Now Not\ Now Done].freeze
  SKIP_SECTIONS   = /\AContext/i
  COLUMN_COLORS   = { "Maybe" => "var(--color-card-3)" }.freeze
  DEFAULT_COLOR   = "var(--color-card-2)"

  def initialize(account, user)
    @account = account
    @user    = user
  end

  def call(note_data)
    board    = find_or_create_board(note_data["name"])
    sections = note_data["sections"] || []

    board.cards.destroy_all

    columns = ensure_columns(board, sections)
    create_cards(board, sections, columns)
  end

  private
    def create_steps(card, steps)
      (steps || []).each do |step|
        card.steps.create!(content: step["text"].truncate(255), completed: step["done"])
      end
    end

    def find_or_create_board(name)
      board = @account.boards.find_or_create_by!(name: name)
      @user.accesses.find_or_create_by!(board: board, account: @account)
      board
    end

    def ensure_columns(board, sections)
      sections.each_with_object({}) do |section, cols|
        name = section["name"]

        next if NATIVE_SECTIONS.include?(name)
        next if name.match?(SKIP_SECTIONS)
        next if (section["todos"] || []).empty?

        color = COLUMN_COLORS.fetch(name, DEFAULT_COLOR)
        cols[name] = board.columns.find_or_create_by!(name: name) do |col|
          col.color = color
        end
      end
    end

    def create_cards(board, sections, columns)
      sections.each do |section|
        name  = section["name"]
        todos = section["todos"] || []

        next if name.match?(SKIP_SECTIONS)

        todos.each do |todo|
          card = board.cards.create!(
            title:   todo["text"].truncate(255),
            creator: @user,
            status:  "published"
          )

          create_steps(card, todo["steps"])

          case name
          when "Now"     then nil
          when "Not Now" then card.postpone(user: @user)
          when "Done"    then card.close(user: @user)
          else
            col = columns[name]
            card.triage_into(col) if col
          end
        end
      end
    end
end

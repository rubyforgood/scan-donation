class SquareTransaction < ApplicationRecord
  validates :square_id, presence: true
  validates :salesforce_id, presence: true

  def self.last_written_time
    self.order(created_at: :asc).last&.created_at
  end
end

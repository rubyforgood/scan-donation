class SquareTransaction < ApplicationRecord
  validates :square_id, presence: true
  validates :salesforce_id, presence: true
end

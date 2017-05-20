class SquareCustomer < ApplicationRecord
  validates :square_id, presence: true
  validates :pushed_as_of, presence: true
end

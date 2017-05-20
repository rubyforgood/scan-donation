require 'test_helper'

class SquareTransactionTest < ActiveSupport::TestCase
  test 'validates square_id' do
    t = SquareTransaction.new(salesforce_id: 1234)
    refute(t.valid?, t.errors)
  end

  test 'validates salesforce_id' do
    t = SquareTransaction.new(square_id: 1234)
    refute(t.valid?, t.errors)
  end
end

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

  test "#last_written_time returns the newest record's time" do
    newest_record_time = 5.minutes.ago
    create_transaction(created_at: newest_record_time)
    create_transaction(created_at: newest_record_time - 1.day)
    create_transaction(created_at: newest_record_time - 1.minute)

    assert_equal(newest_record_time, SquareTransaction.last_written_time)
  end

  def create_transaction(overrides={})
    attributes = {
      square_id: SecureRandom.hex,
      salesforce_id: SecureRandom.hex,
    }.merge(overrides)

    SquareTransaction.create(attributes)
  end
end



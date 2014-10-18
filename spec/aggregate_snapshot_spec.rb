require 'spec_helper'
require 'sandthorn/aggregate_root_snapshot'
require 'date'


module BankAccountInterestCommands
  def calculate_interest! until_date = DateTime.now
    # skipping all safety-checks..
    # and this is of course horribly wrong financially speaking.. whatever
    pay_out_unpaid_interest!
    interest_calculation_time = until_date - @last_interest_calculation
    days_with_interest = interest_calculation_time.to_i
    unpaid_interest = @balance * @current_interest_info[:interest_rate] * days_with_interest / 365.2425
    added_unpaid_interest_event unpaid_interest,until_date
  end

  def pay_out_unpaid_interest!
    paid_out_unpaid_interest_balance_event @unpaid_interest_balance
  end

  def change_interest! new_interest_rate, interest_valid_from
    calculate_interest!
    changed_interest_rate_event new_interest_rate,interest_valid_from
  end
end
module BankAccountWithdrawalCommands
  def withdraw_from_atm! amount, atm_id
    withdrew_amount_from_atm_event amount, atm_id
  end

  def withdraw_from_cashier! amount, cashier_id
    withdrew_amount_from_cashier_event amount, cashier_id
    charged_cashier_withdrawal_fee_event 50
  end
end

module BankAccountVisaCardPurchasesCommands
  def charge_card! amount, merchant_id
    visa = VisaCardTransactionGateway.new
    transaction_id = visa.charge_card "3030-3333-4252-2535", merchant_id, amount
    paid_with_visa_card_event amount, transaction_id
  end

end

class VisaCardTransactionGateway
  def initialize
    @visa_connector = "foo_bar"
  end
  def charge_card visa_card_number, merchant_id, amount
    transaction_id = SecureRandom.uuid
  end
end

module BankAccountDepositCommmands
  def deposit_at_bank_office! amount, cashier_id
    deposited_to_cashier_event amount, cashier_id
  end

  def transfer_money_from_another_account! amount, from_account_number
    incoming_transfer_event amount,from_account_number
  end
end

class BankAccount
  include Sandthorn::AggregateRoot

  attr_reader :balance
  attr_reader :account_number
  attr_reader :current_interest_info
  attr_reader :account_creation_date
  attr_reader :unpaid_interest_balance
  attr_reader :last_interest_calculation

  def initialize *args
    account_number = args[0]
    interest_rate = args[1]
    creation_date = args[2]

    @current_interest_info = {}
    @current_interest_info[:interest_rate] = interest_rate
    @current_interest_info[:interest_valid_from] = creation_date
    @balance = 0
    @unpaid_interest_balance = 0
    @account_creation_date = creation_date
    @last_interest_calculation = creation_date
  end

  def changed_interest_rate_event new_interest_rate, interest_valid_from
    @current_interest_info[:interest_rate] = new_interest_rate
    @current_interest_info[:interest_valid_from] = interest_valid_from
    record_event new_interest_rate,interest_valid_from
  end

  def added_unpaid_interest_event interest_amount, calculated_until
    @unpaid_interest_balance += interest_amount
    @last_interest_calculation = calculated_until
    record_event interest_amount, calculated_until
  end

  def paid_out_unpaid_interest_balance_event interest_amount
    @unpaid_interest_balance -= interest_amount
    @balance += interest_amount
    record_event interest_amount
  end

  def withdrew_amount_from_atm_event amount, atm_id
    @balance -= amount
    record_event amount,atm_id
  end

  def withdrew_amount_from_cashier_event amount, cashier_id
    @balance -= amount
    record_event amount, cashier_id
  end

  def paid_with_visa_card_event amount, visa_card_transaction_id
    @balance -= amount
    record_event amount,visa_card_transaction_id
  end

  def charged_cashier_withdrawal_fee_event amount
    @balance -= amount
    record_event amount
  end

  def deposited_to_cashier_event amount, cashier_id
    @balance = self.balance + amount
    record_event amount,cashier_id
  end

  def incoming_transfer_event amount, from_account_number
    current_balance = self.balance
    @balance = amount + current_balance
    record_event amount, from_account_number
  end

end

def a_test_account
  a = BankAccount.new "91503010111",0.031415, Date.new(2011,10,12)
  a.extend BankAccountDepositCommmands
  a.transfer_money_from_another_account! 90000, "FOOBAR"
  a.deposit_at_bank_office! 10000, "Lars Idorn"

  a.extend BankAccountVisaCardPurchasesCommands
  a.charge_card! 1000, "Starbucks Coffee"

  a.extend BankAccountInterestCommands
  a.calculate_interest!
  return a
end

#Tests part
describe "when doing aggregate_find on an aggregate with a snapshot" do
  let(:aggregate) do
    a = a_test_account
    a.save
    a.extend Sandthorn::AggregateRootSnapshot
    a.aggregate_snapshot!
    a.save_snapshot
    a.charge_card! 9000, "Apple"
    a.save
    a
  end
  it "should be loaded with correct version" do
    org = aggregate
    loaded = BankAccount.find org.aggregate_id
    expect(loaded.balance).to eql org.balance
  end
end

describe 'when generating state on an aggregate root' do

  before(:each) do
    @original_account = a_test_account
    events = @original_account.aggregate_events
    @account = BankAccount.aggregate_build events
    @account.extend Sandthorn::AggregateRootSnapshot
    @account.aggregate_snapshot!
  end

  it 'account should have properties set' do
    expect(@account.balance).to eql 99000
    expect(@account.unpaid_interest_balance).to be > 1000
  end

  it 'should store snapshot data in aggregate_snapshot' do
    expect(@account.aggregate_snapshot).to be_a(Hash)
  end

  it 'should store aggregate_version in aggregate_snapshot' do
    expect(@account.aggregate_snapshot[:aggregate_version]).to eql(@original_account.aggregate_current_event_version)
  end

  it 'should be able to load up from snapshot' do

    events = [@account.aggregate_snapshot]
    loaded = BankAccount.aggregate_build events

    expect(loaded.balance).to eql(@original_account.balance)
    expect(loaded.account_number).to eql(@original_account.account_number)
    expect(loaded.current_interest_info).to eql(@original_account.current_interest_info)
    expect(loaded.account_creation_date).to eql(@original_account.account_creation_date)
    expect(loaded.unpaid_interest_balance).to eql(@original_account.unpaid_interest_balance)
    expect(loaded.last_interest_calculation).to eql(@original_account.last_interest_calculation)
    expect(loaded.aggregate_id).to eql(@original_account.aggregate_id)
    expect(loaded.aggregate_originating_version).to eql(@account.aggregate_originating_version)

  end

end

describe Sandthorn::AggregateRootSnapshot do
  let(:subject) { a_test_account.save.extend Sandthorn::AggregateRootSnapshot  }
  context "when using :snapshot - method" do
    it "should return self" do
      expect(subject.snapshot).to eql subject
    end
    it "should raise SnapshotError if aggregate has unsaved events" do
      subject.paid_with_visa_card_event 2000, ""
      expect{subject.snapshot}.to raise_error Sandthorn::Errors::SnapshotError
    end
  end
end


describe 'when saving to repository' do
  let(:account) {a_test_account.extend Sandthorn::AggregateRootSnapshot}
  it 'should raise an error if trying to save before creating a snapshot' do
    expect(lambda {account.save_snapshot}).to raise_error (Sandthorn::Errors::SnapshotError)
  end
  it 'should not raise an error if snapshot was created' do
    account.save
    account.aggregate_snapshot!
    expect(lambda {account.save_snapshot}).not_to raise_error
  end
  it 'should set aggregate_snapshot to nil' do
    account.save
    account.aggregate_snapshot!
    account.save_snapshot
    expect(account.aggregate_snapshot).to eql(nil)
  end

  it 'should raise error if trying to create snapshot before events are saved on object' do
    expect(lambda {account.aggregate_snapshot!}).to raise_error
  end

  it 'should not raise an error if trying to create snapshot on object when events are saved' do
    account.save
    expect( lambda {account.aggregate_snapshot!}).not_to raise_error
  end

  it 'should get snapshot on account find when a snapshot is saved' do

    account.save
    account.aggregate_snapshot!
    account.save_snapshot

    loaded = BankAccount.find account.aggregate_id

    expect(loaded.balance).to eql(account.balance)
    expect(loaded.account_number).to eql(account.account_number)
    expect(loaded.current_interest_info).to eql(account.current_interest_info)
    expect(loaded.account_creation_date).to eql(account.account_creation_date)
    expect(loaded.unpaid_interest_balance).to eql(account.unpaid_interest_balance)
    expect(loaded.last_interest_calculation).to eql(account.last_interest_calculation)
    expect(loaded.aggregate_id).to eql(account.aggregate_id)
    expect(loaded.aggregate_originating_version).to eql(account.aggregate_originating_version)

  end
end

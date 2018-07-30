require 'rails_helper'
require_relative '../../lib/domain/interface_enforcer'
require_relative '../../lib/domain/i_payment_gateway'

RSpec.describe StripeGateway do
  describe "#initialize" do
    it "implements the Domain::IPaymentGateway interface" do
      expect(
        Domain::InterfaceEnforcer.audit(
          StripeGateway.new, Domain::IPaymentGateway
        )
      ).to be true
    end
  end

  describe "#process_payment" do
    let(:args) {
      { customer_rep: OpenStruct.new(
          name: 'Bob',
          email: 'bobb@mailinator.com',
          stripe_id: 'abc123'),
        amount: 60000,
        payment_token: 'token1234',
        description: 'Registration for 2018 Chi Kung & Kung Fu Festival: Generating Energy Flow, Cosmic Expansion'
      }
    }
    let(:sg) { StripeGateway.new }
    let(:payment_source) {
      double Stripe::Source
    }
    let(:customer) {
      double Stripe::Customer, id: 'abc123'
    }
    let(:charge) {
      double Stripe::Charge, id: 'def456'
    }

    before :each do
      allow(sg).
        to receive(:find_or_create_customer).
             and_return customer
      allow(sg).
        to receive(:create_payment_source).
             and_return payment_source
      allow(sg).
        to receive(:charge_customer).
             and_return charge
      end

    it "raises an error when no customer_rep is supplied" do
      expect {
        sg.process_payment
      }.to raise_error(ArgumentError, /customer_rep/)
    end

    it "raises an error when the customer_rep has no email" do
      expect {
        sg.process_payment(
          args.merge customer_rep: OpenStruct.new(name: 'Bob')
        )
      }.to raise_error(ArgumentError, /email/)
    end

    it "raises an error when no amount is supplied" do
      expect {
        sg.process_payment args.merge amount: nil
      }.to raise_error(ArgumentError, /amount/)
    end

    it "raises an error when no payment_token is supplied" do
      expect {
        sg.process_payment args.merge payment_token: nil
      }.to raise_error(ArgumentError, /payment_token/)
    end

    it "finds or creates the stripe customer" do
      expect(sg).
        to receive(:find_or_create_customer).
             with(args[:customer_rep]).
             and_return customer

      sg.process_payment args
    end

    it "creates a new payment source for the customer using the payment token" do
      expect(sg).
        to receive(:create_payment_source).
             with(customer, args[:payment_token]).
             and_return payment_source

      sg.process_payment args
    end

    it "charges the customer's payment source for the specified amount with the specified description" do
      expect(sg).
        to receive(:charge_customer).
             with(
               amount: 60000,
               customer: customer,
               description: args[:description],
               source: payment_source
             ).
             and_return charge

      sg.process_payment args
    end

    it "succeeds when it successfully creates the charge" do
      expect(sg.process_payment(args)).
        to eq({
                succeeded: true,
                data: {
                  customer_id: 'abc123',
                  charge_id: 'def456'
                }
              })
    end

    it "fails when it can't find or create the customer due to a Stripe::InvalidRequestError" do
      allow(sg).
        to receive(:find_or_create_customer).
             with(args[:customer_rep]).
             and_raise Stripe::InvalidRequestError.new "uh-oh", "customer"

      expect(sg.process_payment args).
        to eq({
                succeeded: false,
                data: {
                  customer_id: nil,
                  charge_id: nil,
                  messages: {
                    customer: ["Unable to find or create the Stripe Customer. Payment canceled."]
                  }
                }
              })

    end

    it "raises an error when it can't find or create the customer due to an unexpected error" do
      allow(sg).
        to receive(:find_or_create_customer).
             with(args[:customer_rep]).
             and_raise RuntimeError.new "uh-oh"

      expect {
        sg.process_payment args
      }.to raise_error(RuntimeError, /uh-oh/)
    end

    it "fails when it can't create the payment source" do
      allow(sg).
        to receive(:create_payment_source).
             with(customer, args[:payment_token]).
             and_raise Stripe::CardError.new "uh-oh", "card", "code"
      expect(sg.process_payment args).
        to eq({
                succeeded: false,
                data: {
                  customer_id: 'abc123',
                  charge_id: nil,
                  messages: { payment_token: [StripeGateway::MESSAGES[:card_declined]] }
                }
              })
    end

    it "fails when it can't create the charge" do
      allow(sg).
        to receive(:charge_customer).
             with(
               amount: 60000,
               customer: customer,
               description: args[:description],
               source: payment_source).
             and_raise Stripe::InvalidRequestError.new "uh-oh", "source"

      expect(sg.process_payment args).
        to eq(
             succeeded: false,
             data: {
               customer_id: customer.id,
               charge_id: nil,
               messages: {
                 payment_token: ["Unable to create the Stripe Charge. Payment canceled."]
               }
             }
           )
    end
  end

  describe "#find_or_create_customer" do
    skip "TODO: Implement tests"
  end

  describe "#create_payment_source" do
    skip "TODO: Implement tests"
  end

  describe "#charge_customer" do
    skip "TODO: Implement tests"
  end
end

require 'rails_helper'

RSpec.describe StripeController, type: :controller do
  describe "POST webhook" do
    let(:successful_invoice_payment) {
      JSON.parse(
        File.read(
          File.expand_path(
            '../../support/sample_invoice_payment_succeeded.json',
            __FILE__
          )))
    }
    let(:event) {
      Stripe::Event.construct_from successful_invoice_payment
    }

    it "returns a 200 to acknowledge receipt of the event before doing anything else"

    it "retrieves the event from stripe by id to verify the event" do
      pending
      expect(Stripe::Event).
        to receive(:retrieve).
            with("evt_00000000000000").
            and_return event
      post :webhook, params: successful_invoice_payment
    end

    it "finds the contract associated with the stripe invoice's subscription" do
      pending
      expect(Contract).
        to receive(:find).with(44)
      post :webhook, params: successful_invoice_payment
    end

    context "when the contract can't be found" do
      it "emails the admin about the missing contract"
    end

    context "when the event is invoice.payment_succeeded" do
      it "updates the student's contract with the payment"
      it "sets the contract's status to 'active' if it isn't already"

      context "when the payment pays off the contract" do
        it "emails the admin that the student's contract is paid off"
        it "emails the student about the successful payment and contract pay off"
        it "cancels the student's subscription"
      end

      context "and the payment doesn't pay off the contract" do
        it "emails the student about the successful payment"
      end
    end

    context "when the event is invoice.payment_failed" do
      it "emails the admin with the failed payment info"
      it "doesn't update the contract balance"
    end

    context "when the event is neither invoice.payment_succeeded nor invoice.payment_failed" do

    end

  end
end

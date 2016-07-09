RSpec.describe RegistrationContext, type: :context do
  let(:user) { build :user }
  let(:course) {
    build(:course).tap do |course|
      course.first_installment_date = course.start_date
    end
  }
  let(:payment_plan) { build :contract_plan, total: 100000 }
  let(:registration) { build :registration, user: user, course: course }
  let(:stripe_token) { 'stripe token value' }
  let(:context) {
    RegistrationContext.new(
      user: user,
      course: course,
      registration: registration,
      payment_plan: payment_plan,
      stripe_token: stripe_token
    )
  }

  describe "#initialize" do
    it "requires a user" do
      expect {
        RegistrationContext.new
      }.to raise_error(ArgumentError, /user/)
    end

    it "requires a course" do
      expect {
        RegistrationContext.new user: double("User")
      }.to raise_error(ArgumentError, /course/)
    end

    it "requires a registration" do
      expect {
        RegistrationContext.new(
          user: double("User"),
          course: double("Course")
        )
      }.to raise_error(ArgumentError, /registration/)
    end

    it "requires a payment plan" do
      expect {
        RegistrationContext.new(
          user: double("User"),
          course: double("Course"),
          registration: double("Registration")
        )
      }.to raise_error(ArgumentError, /payment plan/)
    end

    it "requires a stripe token" do
      expect {
        RegistrationContext.new(
          user: double("User"),
          course: double("Course"),
          registration: double("Registration"),
          payment_plan: double("Payment Plan")
        )
      }.to raise_error(ArgumentError, /stripe token/)
    end

    it "builds a contract from the payment plan, course, and user" do
      contract = context.contract

      expect(contract.user).to eql(user)
      expect(contract.status).to eq('future')
      expect(contract.start_date).to eq(course.start_date)
      expect(contract.end_date).to eq(course.end_date)
      expect(contract.title).to eq(payment_plan.title)
      expect(contract.total).to eq(payment_plan.total)
      expect(contract.balance).to eq(payment_plan.total)
      expect(contract.payment_amount).to eq(payment_plan.payment_amount)
    end
  end

  describe "#call" do
    it "validates the contract and registration" do
      expect(context).
        to receive(:validate_targets).
            and_return({
                         valid: false,
                         error_messages: { tomato: "can't be tomahto" }
                       })

      context.call
    end


    context "when validation passes" do
      before :each do
        allow(context).
          to receive(:validate_targets).
              and_return({
                           valid: true,
                           error_messages: {}
                         })
      end

      it "charges the student based on the payment plan" do
        expect(context).
          to receive(:process_deposit).
              and_return({
                           customer: double("Customer"),
                           card: double("Card"),
                           charge: double("Charge", status: 'failed')
                         })
        context.call
      end


      context "and the charge is successful" do
        let(:deposit_result) {
          {
            payment_succeeded: true,
            customer: double("Customer"),
            card: double("Card"),
            charge: double("Charge", status: 'succeeded')
          }
        }

        before :each do
          allow(context).
            to receive(:process_deposit).
                and_return deposit_result
        end

        it "saves the registration and contract" do
          expect(context).
            to receive(:save_targets).
                and_return false

          context.call
        end

        context "and the registration and contract are saved" do
          before :each do
            allow(context).
              to receive(:save_targets).
                  and_return true
          end

          it "subscribes to a Stripe plan" do
            expect(context).
              to receive(:subscribe_to_plan).
                  with(deposit_result[:customer])

            context.call
          end

          it "returns a successful result when the subscription succeeds" do
            allow(context).
              to receive(:subscribe_to_plan).
                  and_return true

            result = context.call
            expect(result).to be_successful
            expect(result.subscribed).to be true
          end

          it "returns an unsuccessful result when the subscription fails" do
            allow(context).
              to receive(:subscribe_to_plan).
                  and_return false

            result = context.call
            expect(result).to_not be_successful
            expect(result.subscribed).to be false
          end
        end

        context "and the registration and contract are not saved" do
          before :each do
            allow(context).
              to receive(:save_targets).
                  and_return false
          end

          it "returns an unsuccessful result" do
            result = context.call
            expect(result).to_not be_successful
            expect(result.saved).to be false
          end

          it "doesn't create a subscription" do
            expect(context).to_not receive(:subscribe_to_plan)
            context.call
          end
        end
      end

      context "and the charge fails" do
        before :each do
          allow(context).
            to receive(:process_deposit).
                and_return({
                             payment_succeeded: false,
                             message: RegistrationContext::MESSAGES[:card_declined]
                           })
        end

        it "returns an unsuccessful result" do
          result = context.call
          expect(result).to_not be_successful
          expect(result.payment_succeeded).to be false
          expect(result.message).to eq(RegistrationContext::MESSAGES[:card_declined])
        end

        it "doesn't save the registration or contract" do
          expect(context).
            to_not receive(:save_targets)

          context.call
        end

        it "doesn't create a subscription" do
          expect(context).
            to_not receive(:subscribe_to_plan)

          context.call
        end

      end
    end

    context "when validation fails" do
      before :each do
        allow(context).
          to receive(:validate_targets).
              and_return({
                           valid: false,
                           error_messages: { tomato: "can't be tomahto" }
                         })
      end

      it "returns an unsuccessful result" do
        result = context.call
        expect(result).to_not be_successful
        expect(result.valid).to be false
        expect(result.validation_errors).to eq(tomato: "can't be tomahto")
      end

      it "doesn't process the deposit" do
        expect(context).to_not receive(:process_deposit)
        context.call
      end

      it "doesn't save the registration or contract" do
        expect(context).to_not receive(:save_targets)
        context.call
      end

      it "doesn't create a subscription" do
        expect(context).to_not receive(:subscribe_to_plan)
        context.call
      end
    end
  end

  describe "#validate_targets" do
    it "is valid with no error messages if the contract and registration are both valid" do
      expect(context.validate_targets).to eq(valid: true, error_messages: {contract: {}, registration: {}})
    end

    it "is invalid with error messages if the contract is invalid" do
      context.contract.balance = nil
      expect(context.validate_targets).
        to eq(valid: false,
              error_messages: {
                contract: {
                  balance: ["can't be blank"]
                },
                registration: {}
              }
             )
    end

    it "is invalid with error messages if the registration is invalid" do
      context.registration.user = nil
      expect(context.validate_targets).
        to eq(valid: false,
              error_messages: {
                contract: {},
                registration: {
                  user: ["can't be blank"]
                }
              }
             )
    end
  end

  describe "#process_deposit" do
    def customer_double id="stripe customer id"
      double "Customer",
             id: id,
             sources: double("Source", create: card)
    end

    let(:customer) {
      customer_double
    }
    let(:card) {
      double "Stripe Card", id: 'stripe card id'
    }
    let(:charge) {
      double "Stripe Charge", amount: 25000, status: 'succeeded'
    }

    before :each do
      context.user.stripe_id = customer.id
      allow(Stripe::Customer).
        to receive(:retrieve).
            with('stripe customer id').
            and_return customer

      allow(Stripe::Customer).
        to receive(:create).
            and_return customer

      allow(Stripe::Charge).
        to receive(:create).
            and_return charge

      allow(user).
        to receive(:update).
            and_return true
    end

    context "happy path" do
      it "finds the user's Stripe Customer if the user has a stripe id" do
        expect(Stripe::Customer).
          to receive(:retrieve).
              with('stripe customer id').
              and_return customer

        context.process_deposit
      end

      it "creates a Stripe Customer for the user if the user doesn't have a stripe id" do
        context.user.stripe_id = nil
        expect(Stripe::Customer).
          to receive(:create).
              with(email: user.email, description: user.name).
              and_return customer

        context.process_deposit
      end

      it "uses the stripe token to associate a credit card with the Stripe Customer" do
        expect(customer.sources).
          to receive(:create).
              with(source: stripe_token).
              and_return card

        context.process_deposit
      end

      it "creates a Stripe Charge using the Stripe Customer, Stripe Card, and payment plan" do
        expect(Stripe::Charge).
          to receive(:create).
              with(
                amount: payment_plan.deposit,
                currency: 'usd',
                customer: customer.id,
                source: card.id,
                description: anything
              )

        context.process_deposit
      end

      it "records the successful charge on the contract" do
        starting_balance = context.contract.balance
        context.process_deposit
        expect(context.contract.balance).to eq(starting_balance - charge.amount)
      end

      it "returns the customer, card, and charge" do
        expect(context.process_deposit).
          to eq(payment_succeeded: true, customer: customer, card: card, charge: charge)
      end
    end

    context "when the Stripe Customer can't be found" do
      let(:no_customer_error) {
        Stripe::InvalidRequestError.new("No such customer: #{customer.id}", 'id')
      }

      before :each do
        context.user.stripe_id = customer.id
        allow(Stripe::Customer).
          to receive(:retrieve).
              and_raise no_customer_error

        allow(Stripe::Customer).
          to receive(:create).
              with(email: user.email, description: user.name).
              and_return customer_double('other stripe id')
      end

      it "creates a new Stripe Customer and associates it with the user" do
        expect(Stripe::Customer).
          to receive(:create).
              with(email: user.email, description: user.name).
              and_return customer_double('other stripe id')

        expect(context.user).
          to receive(:update).
              with(stripe_id: 'other stripe id')

        context.process_deposit
      end

      it "logs the failure and resolution" do
        expect(Rails.logger).
          to receive(:warn).with /Stripe Customer/

        context.process_deposit
      end
    end

    context "when the Stripe Customer has been deleted" do
      let(:deleted_customer) {
        double("Customer", id: 'deleted stripe customer id', deleted: true)
      }

      before :each do
        allow(Stripe::Customer).
          to receive(:retrieve).
              and_return deleted_customer
      end

      it "creates a new Stripe Customer and associates it with the user" do
        expect(Stripe::Customer).
          to receive(:create).
              with(email: user.email, description: user.name).
              and_return customer_double('other stripe id')

        expect(context.user).
          to receive(:update).
              with(stripe_id: 'other stripe id')

        context.process_deposit
      end

      it "logs the failure and resolution" do
        expect(Rails.logger).
          to receive(:warn).with(/Stripe Customer/)

        context.process_deposit
      end
    end

    context "when the Stripe Customer can't be created" do
      let(:create_customer_error) {
        Stripe::InvalidRequestError.new("Invalid Integer: invalid account balance", 'account_balance')
      }

      before :each do
        context.user.stripe_id = nil

        allow(Stripe::Customer).
          to receive(:create).
              and_raise create_customer_error
      end

      it "logs the error" do
        expect(Rails.logger).
          to receive(:error).
              with(/Stripe Customer/)

        context.process_deposit
      end

      it "returns an unsucceesful result with a message that something went wrong" do
        result = context.process_deposit

        expect(result.keys).to eq([:payment_succeeded, :message])
        expect(result[:payment_succeeded]).to be false
        expect(result[:message]).to match(/problem processing/)
      end
    end

    context "when the Stripe Card can't be created" do
      let(:bad_token_error) {
        Stripe::InvalidRequestError.new("No such token: invalid token value", 'source')
      }
      let(:customer) {
        double "Customer",
               id: 'stripe customer id',
               sources: double("Source")
      }
      let(:stripe_token) { 'invalid token value' }

      before :each do
        context.user.stripe_id = nil

        allow(Stripe::Customer).
          to receive(:create).
              and_return customer

        allow(customer.sources).
          to receive(:create).
              with(source: 'invalid token value').
              and_raise bad_token_error
      end

      it "logs the error" do
        expect(Rails.logger).
          to receive(:error).
              with(/Stripe Card/)

        context.process_deposit
      end

      it "returns an unsuccesful result with a message that something went wrong" do
        result = context.process_deposit

        expect(result.keys).to eq([:payment_succeeded, :message])
        expect(result[:payment_succeeded]).to be false
        expect(result[:message]).to match(/problem processing/)
      end
    end

    context "when the Stripe Card is declined" do
      let(:bad_token_error) {
        Stripe::CardError.new("Your card was declined.", 'source', 'card_error')
      }
      let(:customer) {
        double "Customer",
               id: 'stripe customer id',
               sources: double("Source")
      }
      let(:stripe_token) { 'invalid token value' }

      before :each do
        context.user.stripe_id = nil

        allow(Stripe::Customer).
          to receive(:create).
              and_return customer

        allow(customer.sources).
          to receive(:create).
              with(source: 'invalid token value').
              and_raise bad_token_error
      end

      it "logs the error" do
        expect(Rails.logger).
          to receive(:error).
              with(/Your card was declined/)

        context.process_deposit
      end

      it "returns an unsucceesful result with a message that something went wrong" do
        result = context.process_deposit

        expect(result.keys).to eq([:payment_succeeded, :message])
        expect(result[:payment_succeeded]).to be false
        expect(result[:message]).to match(/card.*declined/)
      end
    end

    context "when the Stripe Charge fails" do
      let(:bad_charge_error ) {
        Stripe::InvalidRequestError.new("Must provie source or customer", 'source')
      }

      before :each do
        allow(Stripe::Charge).
          to receive(:create).
              and_raise bad_charge_error
      end

      it "logs the error" do
        expect(Rails.logger).
          to receive(:error).
              with(/Stripe Charge/)

        context.process_deposit
      end

      it "returns an unsuccessful result with a message to check the credit card info" do
        result = context.process_deposit

        expect(result.keys).to eq([:payment_succeeded, :message])
        expect(result[:payment_succeeded]).to be false
        expect(result[:message]).to match(/problem processing/)
      end
    end
  end

  describe "#save_targets" do
    it "saves the contract and registration and returns true if successful" do
      expect(context.save_targets).to be true
      expect(context.registration).to_not be_new_record
      expect(context.contract).to_not be_new_record
    end

    it "saves nothing and returns false if the contract fails to save" do
      context.contract.title = nil
      expect(context.save_targets).to be false
      expect(context.registration).to be_new_record
      expect(context.contract).to be_new_record
    end

    it "saves nothing and returns false if the registration fails to save" do
      context.registration.course = nil
      expect(context.save_targets).to be false
      expect(context.registration).to be_new_record
      expect(context.contract).to be_new_record
    end
  end

  describe "#subscribe_to_plan" do
    let(:subscription) {
      double "Subscription",
             id: 'stripe subscription id'
    }
    let(:customer) {
      double "Customer",
             subscriptions: double("Subscriptions", create: subscription)
    }

    before :each do
      allow(context.contract).
        to receive(:update_attribute)
    end

    context "when the contract is already paid off" do
      it "returns true without creating a subscription or updating the contract" do
        context.contract.balance = 0

        expect(customer.subscriptions).to_not receive(:create)
        expect(context.contract).to_not receive(:update_attribute)
        expect(context.subscribe_to_plan customer).to be true
      end
    end

    context "when the contract has an outstanding balance" do
      it "creates a Stripe Subscription for the user's Stripe Customer" do
        expect(customer.subscriptions).
          to receive(:create).
              with(
                plan: 'fake stripe plan id',
                metadata: {
                  contract_id: context.contract.id
                },
                trial_end: course.first_installment_date.to_i
              )

        context.subscribe_to_plan customer
      end

      context "and the subscription creation succeeds" do
        it "associates the Stripe Subscription with the contract and returns true" do
          expect(context.contract).
            to receive(:update_attribute).
                with(:stripe_id, 'stripe subscription id').
                and_return true

          expect(context.subscribe_to_plan customer).to be true
        end
      end

      context "and the subscription creation fails" do
        let(:invalid_subscription_error) {
          Stripe::InvalidRequestError.new("Missing required param: plan", 'plan')
        }

        before :each do
          allow(Rails.logger).
            to receive(:error)

          expect(customer.subscriptions).
            to receive(:create).
                and_raise invalid_subscription_error
        end

        it "logs the error" do
          expect(Rails.logger).
            to receive(:error).
                with /subscription/i

          context.subscribe_to_plan customer
        end

        it "returns false without associating the Stripe Subscription with the contract" do
          expect(context.contract).to_not receive(:update_attribute)
          expect(context.subscribe_to_plan customer).to be false
        end
      end
    end
  end
end

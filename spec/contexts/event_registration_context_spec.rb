RSpec.describe EventRegistrationContext, type: :context do
  let(:user) { create :user }
  let(:event) { create :event, title: '2016 Festival' }
  let(:courses) {
    {
      cosmic_expansion:
        create(:event_course,
               title: 'Cosmic Expansion',
               event: event,
               start_date: event.end_date,
               end_date: event.end_date),
      kung_fu:
        create(:event_course,
               title: 'Kung Fu course',
               event: event,
               base_price: 120000,
               start_date: event.start_date,
               end_date: event.end_date),
      energy_flow:
        create(:event_course,
               title: 'Generating Energy Flow',
               event: event,
               start_date: event.start_date,
               end_date: event.start_date),
      ofsz:
        create(:event_course,
               title: 'One Finger Shooting Zen',
               event: event,
               start_date: 1.day.since(event.start_date),
               end_date: 1.day.since(event.end_date))
    }
  }

  let(:context) {
    EventRegistrationContext.new(
      user: user,
      event: event,
      courses: courses.values,
      selected_course_ids: [courses[:cosmic_expansion].id, courses[:kung_fu].id],
      stripe_token: 'stripe token'
    )
  }

  describe "#initialize" do
    it "requires a user" do
      expect {
        EventRegistrationContext.new
      }.to raise_error(ArgumentError, /user/)
    end

    it "requires an event" do
      expect {
        EventRegistrationContext.new user: double(User)
      }.to raise_error(ArgumentError, /event/)
    end

    it "requires selected_course_ids" do
      expect {
        EventRegistrationContext.new(
          user: double(User),
          event: double(Event, courses: [])
        )
      }.to raise_error(ArgumentError, /selected_course_ids/)
    end

    it "requires a stripe token" do
      expect {
        EventRegistrationContext.new(
          user: double(User),
          event: double(Event, courses: []),
          selected_course_ids: [1,2]
        )
      }.to raise_error(ArgumentError, /stripe_token/)
    end

    it "builds an event registration from the user and event" do
      user = build :user
      event = build :event
      context = EventRegistrationContext.new(
        user: user,
        event: event,
        selected_course_ids: [1,2],
        stripe_token: 'stripe token'
      )

      expect(context.event_registration.user).to eql(user)
      expect(context.event_registration.event).to eql(event)
    end
  end

  describe "#call" do
    let(:customer) { double "Stripe Customer" }
    let(:stripe_card) { double "Stripe Card" }
    let(:stripe_charge) { double "Stripe Charge", id: 'stripe_123', status: 'succeeded' }

    before :each do
      allow(context).
        to receive(:calculate_price).
            and_return 150000
      allow(context).
        to receive(:validate_targets).
            and_return({ valid: true, error_messages: {} })
      allow(StripeService).
        to receive(:find_or_create_customer).
            and_return customer
      allow(StripeService).
        to receive(:create_payment_source).
            and_return stripe_card
      allow(StripeService).
        to receive(:charge).
            and_return stripe_charge
      allow(context).
        to receive(:save_targets).
            and_return true
    end

    it "calculates the total price" do
      expect(context).
        to receive(:calculate_price).
            and_return 150000

      context.call
    end

    it "validates the event and course registrations" do
      expect(context).
        to receive(:validate_targets).
            and_return({ valid: true, error_messages: {} })

      context.call
    end

    it "updates and returns the result when validation fails" do
      allow(context).
        to receive(:validate_targets).
          and_return({
            valid: false,
            error_messages: {event_registration: ["is messy"]}
          })

      expect(StripeService).
        not_to receive(:find_or_create_customer)

      result = context.call

      expect(result.valid).to eql(false)
      expect(result.validation_errors).
        to eql({event_registration: ["is messy"]})
    end

    it "finds or creates a Stripe Customer for the user when validation passes" do
      expect(StripeService).
        to receive(:find_or_create_customer).
            with(user).
            and_return double("Stripe Customer")

      context.call
    end

    it "updates and returns the result when finding/creating a Stripe Customer fails" do
      allow(StripeService).
        to receive(:find_or_create_customer).
            and_return nil

      expect(StripeService).
        not_to receive(:create_payment_source)

      result = context.call

      expect(result.payment_succeeded).to eql(false)
      expect(result.message).to match(/try again/i)
    end

    it "creates a new Stripe payment source (credit card) for the user/stripe customer when finding/creating a Stripe Customer succeeds" do
      expect(StripeService).
        to receive(:create_payment_source).
            with(user, customer, 'stripe token').
            and_return stripe_card

      context.call
    end

    it "updates and returns the result when the Stripe payment source is declined/invalid" do
      allow(StripeService).
        to receive(:create_payment_source).
            and_raise(Stripe::CardError.new('big time card error', 'param', 'invalid_date'))

      expect(StripeService).
        not_to receive(:charge)

      result = context.call

      expect(result.payment_succeeded).to eql(false)
      expect(result.message).to match(/card.*declined/i)
    end

    it "updates and returns the result when creating a Stripe payment source fails for another reason" do
      allow(StripeService).
        to receive(:create_payment_source).
            and_raise(Stripe::InvalidRequestError.new('invalid request', 'param'))

      expect(StripeService).
        not_to receive(:charge)

      result = context.call

      expect(result.payment_succeeded).to eql(false)
      expect(result.message).to match(/try again/i)
    end

    it "charges the customer's card for the correct amount when creating a Stripe payment source succeeds" do
      expect(StripeService).
        to receive(:charge).
            with({
              customer: customer,
              source: stripe_card,
              amount: 150000,
              description: "2016 Festival: Cosmic Expansion, Kung Fu course"
            }).
            and_return stripe_charge

      context.call
    end

    it "updates and returns the result when the charge fails" do
      allow(StripeService).
        to receive(:charge).
            and_return nil

      expect(context).
        not_to receive(:save_targets)

      result = context.call

      expect(result.payment_succeeded).to eql(false)
      expect(result.message).to match(/try again/i)
    end

    it "updates and returns the result when the charge has a status other than 'succeeded'" do
      allow(StripeService).
        to receive(:charge).
            and_return double("Stripe Charge", id: 'stripe_123', status: 'failed')

      expect(context).
        not_to receive(:save_targets)

      result = context.call

      expect(result.payment_succeeded).to eql(false)
      expect(result.message).to be_blank
    end

    it "saves the event and course registrations when the charge is successful" do
      course_regs = {
        "#{courses[:cosmic_expansion].id}" =>
          double(Registration, user: user, course: courses[:cosmic_expansion]),
        "#{courses[:kung_fu].id}" =>
          double(Registration, user: user, course: courses[:kung_fu])
      }

      allow(user.registrations).
        to receive(:build) do |attrs|
          course_regs["#{attrs[:course].id}"]
        end

      expect(context).
        to receive(:save_targets).
            with(course_regs.values + [context.event_registration]).
            and_return true

      context.call
    end

    it "updates the result with the outcome of the save call" do
      result = context.call
      expect(result.saved).to eql(true)
    end
  end

  describe "#calculate_price" do
    let!(:ck_discount) {
      event.discounts.build(
            description: "Both Chi Kung Courses + One Finger Shooting Zen",
            course_list:
              [:cosmic_expansion, :energy_flow, :ofsz]
                .map {|c| courses[c].id }
                .join(','),
            price: 60000
      )
    }
    let!(:all_discount) {
      event.discounts.build(
            description: "All Courses",
            course_list: courses.values.map(&:id).join(','),
            price: 150000
      )
    }
    let!(:kf_ofsz_discount) {
      event.discounts.build(
        description: "One Finger Shooting Zen + Crossroads at Four Gates",
        course_list:
          [:kung_fu, :ofsz]
            .map {|c| courses[c].id }
            .join(','),
        price: 120000
      )
    }

    it "doesn't apply a discount when none apply" do
      context = EventRegistrationContext.new(
        user: user,
        event: event,
        courses: courses.values,
        selected_course_ids:
          [:energy_flow, :cosmic_expansion].map {|c| courses[c].id },
        stripe_token: 'stripe token'
      )

      expect(context.calculate_price).to eql(60000)
    end

    it "applies a discount when only one applies" do
      context = EventRegistrationContext.new(
        user: user,
        event: event,
        courses: courses.values,
        selected_course_ids:
          [:kung_fu, :ofsz].map {|c| courses[c].id },
        stripe_token: 'stripe token'
      )

      expect(context.calculate_price).to eql(120000)
    end

    it "applies the cheapest discount when multiple ones apply" do
      context = EventRegistrationContext.new(
        user: user,
        event: event,
        courses: courses.values,
        selected_course_ids: courses.values.map(&:id),
        stripe_token: 'stripe token'
      )

      expect(context.calculate_price).to eql(150000)
    end


  end

  describe "#validate_targets" do
    let(:course_regs) {
      context.selected_courses.map {|c|
        user.registrations.build course: c
      }
    }

    it "is valid with no error messages when all supplied targets are valid" do
      targets = course_regs + [context.event_registration]
      expect(context.validate_targets targets)
        .to eq(
              valid: true,
              error_messages: {event_registration: {}, registration: {}}
            )

    end

    it "is invalid with error messages when the event registration is invalid" do
      context.event_registration.user = nil
      targets = course_regs + [context.event_registration]
      expect(context.validate_targets targets)
        .to eq(valid: false,
               error_messages: {
                 event_registration: {
                   user: ["can't be blank"] },
                 registration: {}
               }
              )
    end

    it "is invalid with error messages when any of the course registrations are invalid" do
      course_regs.first.user = nil
      targets = course_regs + [context.event_registration]
      expect(context.validate_targets targets)
        .to eq(valid: false,
               error_messages: {
                 event_registration: {
                   user: ["is invalid"]
                 },
                 registration: {
                   user: ["can't be blank"]
                 }
               }
              )
    end
  end

  describe "#save_targets" do
    let(:course_regs) {
      context.selected_courses.map {|c|
        user.registrations.build course: c
      }
    }

    it "saves the course registrations and event registration and returns true if successful" do
      targets = course_regs + [context.event_registration]
      expect(context.save_targets targets).to eq(true)
      expect(context.event_registration).to_not be_new_record
      expect(course_regs.map(&:new_record?).uniq).to eq([false])
    end

    it "saves nothing and returns false if the event registration fails to save" do
      context.event_registration.user = nil
      targets = course_regs + [context.event_registration]
      expect(context.save_targets targets).to eq(false)
      expect(context.event_registration).to be_new_record
      expect(course_regs.map(&:new_record?).uniq).to eq([true])
    end

    it "saves nothing and returns false if any of the course registrations fail to save" do
      course_regs.last.course = nil
      targets = course_regs + [context.event_registration]
      expect(context.save_targets targets).to eq(false)
      expect(context.event_registration).to be_new_record
      expect(course_regs.map(&:new_record?).uniq).to eq([true])
    end
  end
end

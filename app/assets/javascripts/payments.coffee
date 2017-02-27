$(document).ready ->
  Stripe.setPublishableKey $('meta[name="stripe-key"]').attr('content')

  $('.payment_form').submit (event) ->
    event.preventDefault()

    # clear form messages
    $(".alert").remove()
    $(".flash").remove()
    $(".help-block").remove()
    $(".has-error").removeClass('has-error')

    $cardFields = {
      number: $('.payment_form input.card_number')
      cvc: $('.payment_form input.card_cvc')
      exp_month: $('.payment_form select.card_exp_month')
      exp_year: $('.payment_form select.card_exp_year')
      name: $('.payment_form input.card_name')
      address_zip: $('.payment_form input.card_address_zip')
    }
    $submit = $(".payment_form input[type='submit']")
    $submit.attr("disabled", "disabled")

    Stripe.card.createToken({
      number: $cardFields.number.val()
      cvc: $cardFields.cvc.val()
      exp_month: $cardFields.exp_month.val()
      exp_year: $cardFields.exp_year.val()
      name: $cardFields.name.val()
      address_zip: $cardFields.address_zip.val()
    }, (status, response) ->
      if error = response.error
        $("nav").after $("<div class='alert alert-danger' role='alert'>There are some problems with your registration that prevented its submission. Please review the form below and re-submit when you have fixed the problems.</div>")
        $(":input.card_#{error.param}").parent("div").addClass("has-error")
        $errorMsg = $("<span class='help-block'>#{error.message}</span>")
        $(":input.card_#{error.param}").before $errorMsg
        $submit.removeAttr 'disabled'
        scrollTo 0,0
      else
        token = response.id
        $('.payment_form').append("<input type='hidden' name='stripe_token' value='#{token}' />")
        $('.payment_form').get(0).submit()
    )

  displayAmount = (amount) -> "$#{amount/100}"

  monthlyDesc = (selectedPlan) ->
    if _.isEmpty(selectedPlan)
      return ''

    if selectedPlan.deposit? && selectedPlan.deposit > 0
      "Your card will be charged <strong>#{displayAmount(selectedPlan.deposit)}</strong> now and <strong>#{displayAmount(selectedPlan.payment_amount)}</strong> each month of the course, starting with the second month (<strong>#{displayAmount(selectedPlan.total)}</strong> total)."
    else
      "Your card will <strong>not</strong> be charged now, but will be charged <strong>#{displayAmount(selectedPlan.payment_amount)}</strong> on the first day of the course and each month after (<strong>#{displayAmount(selectedPlan.total)} total)."

  inFullDesc = (selectedPlan) ->
    if _.isEmpty(selectedPlan)
      return ''

    "Your card will be charged <strong>#{displayAmount(selectedPlan.total)}</strong> now with no additional payments during the course."

  monthlyAnnualDesc = (selectedPlan) ->
    if _.isEmpty(selectedPlan)
      return ''

    "Your card will be charged <strong>#{displayAmount(selectedPlan.deposit)}</strong> now and <strong>#{displayAmount(selectedPlan.payment_amount)}</strong> each month for the next year (<strong>#{displayAmount(selectedPlan.total)}</strong> total in 12 payments)."

  annualDesc = (selectedPlan) ->
    if _.isEmpty(selectedPlan)
      return ''

    "Your card will be charged <strong>#{displayAmount(selectedPlan.total)}</strong> now with no additional payments for a year."

  planOptions = ->
    $('.payment_desc').data('contractPlans').map (cp) -> JSON.parse(cp)

  $('.payment_form select.payment_plan').change ->
    $selectedPlan = $('.payment_form select.payment_plan option:selected')
    selectedPlan = _.find planOptions(), (po) -> po.id == Number($selectedPlan.val())

    $('.payment_desc').hide().html ''

    # TODO: move the payment descriptions into the contract plans themselves
    if $selectedPlan.text().match /weekly.*monthly/i
      $('.payment_desc').html monthlyAnnualDesc(selectedPlan)
      $('.payment_desc').show()
    else if $selectedPlan.text().match /weekly.*annual/i
      $('.payment_desc').html annualDesc(selectedPlan)
      $('.payment_desc').show()
    else if $selectedPlan.text().match /monthly/i
      $('.payment_desc').html monthlyDesc(selectedPlan)
      $('.payment_desc').show()
    else if $selectedPlan.text().match /full/i
      $('.payment_desc').html inFullDesc(selectedPlan)
      $('.payment_desc').show()
    else
      # don't show

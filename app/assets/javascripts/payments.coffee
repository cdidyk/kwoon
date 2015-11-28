$(document).ready ->
  Stripe.setPublishableKey $('meta[name="stripe-key"]').attr('content')

  $('.payment_form').submit (event) ->
    event.preventDefault()

    # clear form messages
    $(".flash").remove()
    $(".help-block").remove()

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
        $errorMsg = $(":input.card_#{error.param} ~ .help-block")
        if not _.isEmpty $errorMsg
          $errorMsg.text error.message
        else
          $errorMsg = $("<span class='help-block'>#{error.message}</span>")
          $(":input.card_#{error.param}").before $errorMsg
        $submit.removeAttr 'disabled'
      else
        token = response.id
        # $('.token_error').hide()
        $('.payment_form').append("<input type='hidden' name='stripe_token' value='#{token}' />")
        $('.payment_form').get(0).submit()
    )

  $('.payment_form select.payment_plan').change ->
    $selectedPlan = $('.payment_form select.payment_plan option:selected')
    $('.payment_desc').hide()

    if $selectedPlan.text().match /monthly/i
      $('.payment_desc.monthly').show()
    else if $selectedPlan.text().match /full/i
      $('.payment_desc.full').show()
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
      exp_month: $('.payment_form input.card_exp_month')
      exp_year: $('.payment_form input.card_exp_year')
    }
    $submit = $(".payment_form input[type='submit']")
    $submit.attr("disabled", "disabled")

    Stripe.card.createToken({
      number: $cardFields.number.val()
      cvc: $cardFields.cvc.val()
      exp_month: $cardFields.exp_month.val()
      exp_year: $cardFields.exp_year.val()
    }, (status, response) ->
      if error = response.error
        $errorMsg = $("input.card_#{error.param} ~ .help-block")
        if not _.isEmpty $errorMsg
          $errorMsg.text error.message
        else
          $errorMsg = $("<span class='help-block'>#{error.message}</span>")
          $("input.card_#{error.param}").after $errorMsg
        $submit.removeAttr 'disabled'
      else
        token = response.id
        # $('.token_error').hide()
        $('.payment_form').append("<input type='hidden' name='stripe_token' value='#{token}' />")
        $('.payment_form').get(0).submit()
    )

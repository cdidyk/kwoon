@CourseCalculator = ($courseSelector, $discounts, isSelected, update) ->
  calculate = ->
    totalPrice = 0
    selectedCourses = []
    courses = []
    $courseSelector.each (i, el) ->
      $el = $(el)
      course =
        id: $el.val()
        price: $el.data('price')

      if isSelected(el)
        selectedCourses.push course
        totalPrice += course.price

    undiscountedPrice = totalPrice

    discounts = []
    $discounts.each (i, el) ->
      $el = $(el)
      discount =
        courseList: $el.data('course_list').split(',')
        price: $el.data('price')
      discounts.push discount

      [discountable, notDiscountable] =
        _.partition(
          selectedCourses,
          (c) -> _.includes(discount.courseList, c.id)
        )
      discountApplies = discountable.length == discount.courseList.length
      if discountApplies
        priceWithDiscount = discount.price + _.sum(notDiscountable.map((c) -> c.price))
        if priceWithDiscount < totalPrice
          totalPrice = priceWithDiscount

    return {totalPrice, undiscountedPrice}

  $courseSelector.change (e) ->
    {totalPrice, undiscountedPrice} = calculate()
    update(totalPrice, undiscountedPrice)

  return {
    calculate
  }
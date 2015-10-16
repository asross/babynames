$ ->
  $storyCarousel = $('#story-carousel')

  $carouselIndicators = $storyCarousel.find('.carousel-indicators')
  
  $storyCarousel.find('.item').each (i) ->
    $carouselIndicators.append("<li data-target='#story-carousel' data-slide-to='#{i}'></li>")
    $chartDiv = $("<div class='story-chart'></div>")
    $chartDiv.appendTo($(@))
    chart = new NameChart($chartDiv[0])
    series = $(@).data('names').map (n) ->
      name = n.split(':')[0]
      gender = n.split(':')[1]
      { name: name, gender: gender, values: dataByName[gender][name].data }
    chart.drawSeries(series)

    yearData = $(@).data('years').map((yd) -> yd.split(':'))
    orient = $(@).data('orient')

    nameLabels = $(@).data('names').map (n) ->
      name = n.split(':')[0]
      gender = n.split(':')[1]
      "#{genderSymbols[gender]} #{name}"

    chart.drawVerticalLines(yearData.map((yd) -> { year: parseInt(yd[0]) }))
    chart.setTitle(nameLabels.toSentence())

    captionClass = $(@).data('cls')

    yearData.forEach (yd) ->
      year = parseInt(yd[0])
      image = yd[1]
      link = yd.slice(2,4).join(':')
      $caption = $("<div class='chart-caption chart-caption-#{captionClass}'></div>")
      $img = $("<img src='#{image}'/>")
      $span = $("<span>#{year}</span>")
      leftPos = chart.x([year]) + chart.margin.left
      $caption.css(left: leftPos)

      if orient == 'top'
        $caption.css(top: 20)
      else
        $caption.css(bottom: chart.margin.bottom + 10)

      if link
        $a = $("<a href='#{link}' target='_blank'></a>")
        $a.append($img)
        $caption.append($a)
      else
        $caption.append($img)
      $caption.append($span)
      $chartDiv.append($caption)

  $carouselIndicators.find('li:first-child').addClass('active')
  $storyCarousel.find('.item:first-child').addClass('active')

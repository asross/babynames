$ ->
  $('#gender-carousel').carousel(interval: false)

  $('.gender-chart').each ->
    chart = new NameChart(this, {
      colorize: (d) -> @genderColor(d)
      defaultChartWidth: $(@).data('width') || 475
      xTickFormat: (d) ->
        "'#{d.toString().slice(2)}"
      legendPlacement: (d, i) ->
        { x: 0.5*@width - 75*i, y: @height + 40 }
    })

    name = $(@).data('name')

    series = [
      { name: name, gender: 'm', values: dataByName['m'][name].data },
      { name: name, gender: 'f', values: dataByName['f'][name].data }
    ]

    if $(@).hasClass('ftm')
      chart.setTitle "#{genderSymbols.f} #{name} → #{genderSymbols.m} #{name}"
      chart.drawSeries(series)
    else
      chart.setTitle "#{genderSymbols.m} #{name} → #{genderSymbols.f} #{name}"
      chart.drawSeries(series.reverse())

    if year = $(@).data('line')
      chart.drawVerticalLines([[year]])
      if image = $(@).data('image')
        $img = $("<img class='chart-caption-image' src='#{image}'/>")
        $img.css
          bottom: chart.margin.bottom + 10
          left: chart.x([year]) + chart.margin.left
        $span = $("<span class='chart-caption-text'>#{year}</span>")
        $span.css
          bottom: chart.margin.bottom + 11
          left: chart.x([year]) + chart.margin.left
        $(@).append($img)
        $(@).append($span)



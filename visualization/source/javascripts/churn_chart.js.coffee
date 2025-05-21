window.namesByChurn = (minLustrum, maxLustrum, genders) -> # minLustrum is minQueryYear, maxLustrum is maxQueryYear
  result = []

  # Ensure minAuc is not present (it was an unused variable)
  # Example: if a line `minAuc = 1000` exists, remove it.

  roundedMinQueryYear = roundTo(5, minLustrum) # Use minLustrum from params
  roundedMaxQueryYear = roundTo(5, maxLustrum) # Use maxLustrum from params

  minLustrumIdx = lustra.indexOf(roundedMinQueryYear)
  maxLustrumIdx = lustra.indexOf(roundedMaxQueryYear)

  # Clamp min index to earliest available data if query is too early
  if minLustrumIdx == -1 and roundedMinQueryYear < lustra[0]
    minLustrumIdx = 0
  
  # Clamp max index to latest available data if query is too late
  if maxLustrumIdx == -1 and roundedMaxQueryYear > lustra[lustra.length - 1]
    maxLustrumIdx = lustra.length - 1

  # Validate indices after clamping:
  # If minLustrumIdx or maxLustrumIdx are still -1, it means the
  # query year (e.g. roundedMinQueryYear) was outside the entire lustra range
  # in a way that clamping didn't apply (e.g., min query year was > last lustra year).
  # Also, if minLustrumIdx > maxLustrumIdx, the resulting range is invalid.
  # In these cases, return an empty result.
  if minLustrumIdx == -1 or maxLustrumIdx == -1 or minLustrumIdx > maxLustrumIdx
    return result # Return empty array

  for gender in genders
    for name, metrics of dataByName[gender]
      continue if name == 'Unknown'
      
      averages = metrics.fiveYearData
      
      pre = rankOf averages[minLustrumIdx]
      post = rankOf averages[maxLustrumIdx]
      
      continue unless pre < 998 # Original condition
      
      churn = post - pre
      result.push([churn, gender, name])

  result.sort((a, b) -> a[0] - b[0])
  # CoffeeScript implicitly returns the last expression (result)

window.minNamesInput = document.getElementById('min-churn-names')
window.maxNamesInput = document.getElementById('max-churn-names')
window.minYearsInput = document.getElementById('min-churn-years')
window.maxYearsInput = document.getElementById('max-churn-years')
window.$churnBoth = $('#churn-both')
window.$churnMale = $('#churn-male')
window.$churnFemale = $('#churn-female')

window.risingNamesChart = new NameChart document.getElementById('rising-names'), {
  showYAxisLabel: true
  sanitizeLine: (l) -> l
  xDomain: [1880, window.max_year]
}

window.fallingNamesChart = new NameChart document.getElementById('falling-names'), {
  sanitizeLine: (l) -> l
  xDomain: [1880, window.max_year]
}

window.mapChurn = (arr) ->
  arr.map (el) ->
    { name: el[2], gender: el[1], values: dataByName[el[1]][el[2]].fiveYearData }

churnYearSlider = document.getElementById('churn-year-slider')

noUiSlider.create(churnYearSlider, {
  start: [1990, 2000],
  connect: true,
  step: 5,
  margin: 5,
  animate: false,
  behaviour: 'tap-drag',
  range: { min: 1880, max: window.max_year },
  pips: { mode: 'values', values: (y for y in [1880..roundUpTo(10, window.max_year)] by 10) }
})

churnYearSlider.noUiSlider.on 'slide', (values, handle, unencoded) ->
  y1 = Math.round parseFloat(unencoded[0])
  y2 = Math.round parseFloat(unencoded[1])
  minYearsInput.value = y1
  maxYearsInput.value = y2
  redrawChurn()

window.redrawChurn = ->
  y1 = parseInt(minYearsInput.value)
  y2 = parseInt(maxYearsInput.value)
  n1 = parseInt(minNamesInput.value)
  n2 = parseInt(maxNamesInput.value)

  return unless y2 > y1 and n2 > n1

  churnYearSlider.noUiSlider.set([roundTo(5, y1), roundTo(5, y2)])

  if $churnBoth.hasClass('active')
    genders = ['m', 'f']
    nameText = 'Names'
  else if $churnMale.hasClass('active')
    genders = ['m']
    nameText = genderLabels[genders[0]]
  else if $churnFemale.hasClass('active')
    genders = ['f']
    nameText = genderLabels[genders[0]]

  namesWithMostChurn = namesByChurn(y1, y2, genders)

  risingNamesChart.setTitle("Rising #{nameText} #{y1}-#{y2} ↗")
  risingNamesChart.drawSeries mapChurn(namesWithMostChurn.slice(n1, n2))

  fallingNamesChart.setTitle("Falling #{nameText} #{y1}-#{y2} ↘")
  fallingNamesChart.drawSeries mapChurn(namesWithMostChurn.revslice(n1, n2))

redrawChurn()

minNamesInput.oninput = -> redrawChurn()
maxNamesInput.oninput = -> redrawChurn()
minYearsInput.oninput = -> redrawChurn()
maxYearsInput.oninput = -> redrawChurn()

$('#churn-controls .btn-group button').click ->
  $(@).siblings('button').removeClass('active')
  $(@).addClass('active')
  redrawChurn()

$('#churn-chart-spinner').remove()

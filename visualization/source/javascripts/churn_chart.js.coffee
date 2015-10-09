window.lustrums = (x for x in [1880..2010] by 5)

for gender, actualDataByName of dataByName
  for name, info of actualDataByName
    buckets = {}
    buckets[lustrum] = [] for lustrum in lustrums
    info.d.forEach (point) ->
      lustrum = roundDownTo 5, yearOf(point)
      buckets[lustrum].push rankOf(point)
    info.f = []
    for lustrum, ranks of buckets
      rank = ranks.concat([1000,1000,1000,1000,1000]).slice(0, 5).mean()
      info.f.push([lustrum, rank])

window.namesByChurn = (minLustrum, maxLustrum, genders) ->
  result = []
  minAuc = 1000
  minLustrum = roundTo(5, minLustrum)
  maxLustrum = roundTo(5, maxLustrum)
  for gender in genders
    for name, metrics of dataByName[gender]
      continue unless metrics.a >= minAuc
      averages = metrics.f
      pre = averages[lustrums.indexOf(minLustrum)][1]
      post = averages[lustrums.indexOf(maxLustrum)][1]
      continue unless pre < 998
      churn = post - pre
      result.push([churn, gender, name])

  result.sort((a, b) -> a[0] - b[0])

window.minNamesInput = document.getElementById('min-churn-names')
window.maxNamesInput = document.getElementById('max-churn-names')
window.minYearsInput = document.getElementById('min-churn-years')
window.maxYearsInput = document.getElementById('max-churn-years')
window.$churnBoth = $('#churn-both')
window.$churnMale = $('#churn-male')
window.$churnFemale = $('#churn-female')

window.risingNamesChart = new NameChart document.getElementById('rising-names'), sanitizeLine: (l) -> l
window.fallingNamesChart = new NameChart document.getElementById('falling-names'), sanitizeLine: (l) -> l

window.mapChurn = (arr) ->
  arr.map (el) ->
    { name: el[2], gender: el[1], values: dataByName[el[1]][el[2]].f }

churnYearSlider = document.getElementById('churn-year-slider')
noUiSlider.create(churnYearSlider, {
  start: [1990, 2000],
  connect: true,
  step: 5,
  margin: 5,
  animate: false,
  behaviour: 'tap-drag',
  range: { min: 1880, max: 2010 },
  pips: { mode: 'count', values: 14 }
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

  churnYearSlider.noUiSlider.set([
    roundTo(5, y1),
    roundTo(5, y2),
  ])

  if $churnBoth.hasClass('active')
    genders = ['m', 'f']
    nameText = 'Names'
  else if $churnMale.hasClass('active')
    genders = ['m']
    nameText = genderLabels[genders[0]]
  else if $churnFemale.hasClass('active')
    genders = ['f']
    nameText = genderLabels[genders[0]]

  window.namesWithMostChurn = namesByChurn(y1, y2, genders)

  risingNamesChart.drawSeries mapChurn(namesWithMostChurn.slice(n1, n2))
  fallingNamesChart.drawSeries mapChurn(namesWithMostChurn.revslice(n1, n2))

  risingNamesChart.setTitle("Rising #{nameText} #{y1}-#{y2} ↗")
  fallingNamesChart.setTitle("Falling #{nameText} #{y1}-#{y2} ↘")

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

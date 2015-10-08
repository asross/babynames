window.genderSymbols = { m: '♂', f: '♀' }
window.genderLabels = { m: 'Boy Names', f: 'Girl Names' }
window.genderStubs = { m: 'boy', f: 'girl' }

window.nameSelect = document.getElementById('name')
window.yearInput = document.getElementById('year-input')
window.rankInput = document.getElementById('rank-input')
window.stepInput = document.getElementById('step-input')
window.simsInput = document.getElementById('sims-input')

for gender, actualDataByName of dataByName
  optgroup = document.createElement('optgroup')
  optgroup.label = genderLabels[gender]

  for name in Object.keys(actualDataByName).sort()
    option = document.createElement('option')
    option.value = JSON.stringify(gender: gender, name: name)
    option.text = genderSymbols[gender]+' '+name
    option.id = gender+':'+name
    optgroup.appendChild(option)

  nameSelect.appendChild(optgroup)

$(nameSelect).chosen()

yearInput.value = 1880
rankInput.value = 1

window.currentGender = -> JSON.parse(nameSelect.value).gender
window.currentName = -> JSON.parse(nameSelect.value).name

nameSelect.onchange = ->
  data = dataByName[currentGender()][currentName()].data
  yearInput.value = data[0].year
  rankInput.value = data[0].rank
  redraw()

yearInput.oninput = -> redraw()
rankInput.oninput = -> redraw()
simsInput.oninput = -> redraw()

window.currentScale = 'rank'

$rankScale = $('#scale-rank')
$rankScale.click ->
  window.currentScale = 'rank'
  redraw()

$pctgScale = $('#scale-percentage')
$pctgScale.click ->
  window.currentScale = 'percentage'
  redraw()

$maleGenderButton = $('#gender-male')
$maleGenderButton.click ->
  name = dataByYear['m'][yearInput.value][rankInput.value - 1].name
  nameSelect.value = JSON.stringify(gender: 'm', name: name)
  redraw()

$femaleGenderButton = $('#gender-female')
$femaleGenderButton.click ->
  name = dataByYear['f'][yearInput.value][rankInput.value - 1].name
  nameSelect.value = JSON.stringify(gender: 'f', name: name)
  redraw()

stepInput.oninput = ->
  data = dataByName[currentGender()][currentName()].data
  datum = data[parseInt(this.value)]
  yearInput.value = datum.year
  rankInput.value = datum.rank
  redraw()

yearSlider = document.getElementById('year-slider')
noUiSlider.create(yearSlider, {
  start: 1880,
  connect: 'lower',
  animate: false,
  step: 1,
  range: { min: 1880, max: 2014 }
})

rankSlider = document.getElementById('rank-slider')
noUiSlider.create(rankSlider, {
  start: 1,
  connect: 'lower',
  orientation: 'vertical',
  animate: false,
  step: 1,
  range: { min: 1, max: 999 }
})

mainChart = new NameChart(document.getElementById('main-chart'))

simChart = new NameChart(document.getElementById('similar-names'), {
  legendClick: (d) ->
    nameSelect.value = JSON.stringify(gender: d.gender, name: d.name)
    nameSelect.onchange()
})

window.$currentGender = $('.current-gender')
window.$currentPercentage = $('.current-percentage')
window.$currentName = $('.current-name')
window.$currentRank = $('.current-rank')
window.$currentYear = $('.current-year')

window.redraw = ->
  year = parseInt(yearInput.value)
  rank = parseInt(rankInput.value)
  gender = currentGender()
  genderSymbol = genderSymbols[gender]
  genderStub = genderStubs[gender]

  name = dataByYear[gender][year][rank - 1].name
  nameInfo = dataByName[gender][name]
  data = nameInfo.data

  # compute point along path
  step = 0
  for datum in data
    break if datum.year == year
    step += 1
  stepInput.max = data.length - 1
  stepInput.value = step

  point = data[step]
  percentage = point.percentage

  yearSlider.noUiSlider.set(year)
  rankSlider.noUiSlider.set(rank)

  nameSelect.value = JSON.stringify(gender: gender, name: name)
  $(nameSelect).trigger('chosen:updated')

  $currentGender.text(genderStubs[gender])
  $currentPercentage.text(percentage)
  $currentName.text(name)
  $currentRank.text(rank)
  $currentYear.text(year)

  mainChart.setScale(currentScale)
  mainChart.drawLine(data)
  mainChart.drawCircle(data[step])

  if currentScale == 'rank'
    $rankScale.addClass('active')
    $pctgScale.removeClass('active')
    mainChart.setTitle("Popularity of #{genderSymbol} #{name}")
  else
    $pctgScale.addClass('active')
    $rankScale.removeClass('active')
    mainChart.setTitle("% of #{genderStub}s named #{name}")

  if currentGender() == 'm'
    $maleGenderButton.addClass('active')
    $femaleGenderButton.removeClass('active')
  else
    $femaleGenderButton.addClass('active')
    $maleGenderButton.removeClass('active')

  closestNames = nameInfo.closest_names.slice(0,simsInput.value).map (n) ->
    { name: n[2], gender: n[1], values: dataByName[n[1]][n[2]].data }

  simChart.setScale(currentScale)
  simChart.drawSeries(closestNames)
  if nameInfo.closest_names.length > 0
    simChart.setTitle "#{simsInput.value} names most similar to #{genderSymbol} #{name}"
  else
    simChart.setTitle "Not enough data for #{genderSymbol} #{name} to chart similarities"

window.clamp = (n, min, max) ->
  Math.min(Math.max(n, min), max)

window.redraw()

circleDrag = d3.behavior.drag()

circleDrag.on 'dragstart', ->
  mainChart.circle.classed('dragging', true)

circleDrag.on 'drag', ->
  yearInput.value = clamp(
    Math.round(mainChart.xScale.invert(d3.event.x)),
    mainChart.xDomain[0],
    mainChart.xDomain[1])
  rankInput.value = clamp(
    Math.round(mainChart.rankScale.invert(d3.event.y)),
    mainChart.rankDomain[1],
    mainChart.rankDomain[0])
  redraw()

circleDrag.on 'dragend', ->
  mainChart.circle.classed('dragging', false)

circleDrag.call(mainChart.circle)

rankSlider.noUiSlider.on 'slide', (values, handle, unencoded) ->
  rankInput.value = parseInt(unencoded)
  window.redraw()

yearSlider.noUiSlider.on 'slide', (values, handle, unencoded) ->
  yearInput.value = parseInt(unencoded)
  window.redraw()

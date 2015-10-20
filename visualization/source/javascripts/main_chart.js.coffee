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
  yearInput.value = yearOf data[0]
  rankInput.value = rankOf data[0]
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
  name = dataByYear['m'][yearInput.value][rankInput.value - 1][0]
  nameSelect.value = JSON.stringify(gender: 'm', name: name)
  redraw()

$femaleGenderButton = $('#gender-female')
$femaleGenderButton.click ->
  name = dataByYear['f'][yearInput.value][rankInput.value - 1][0]
  nameSelect.value = JSON.stringify(gender: 'f', name: name)
  redraw()

stepInput.oninput = ->
  data = dataByName[currentGender()][currentName()].data
  datum = data[parseInt(this.value)]
  yearInput.value = yearOf datum
  rankInput.value = rankOf datum
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

mainChart = new NameChart(document.getElementById('main-chart'), showYAxisLabel: true)

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

  name = dataByYear[gender][year][rank - 1][0]
  nameInfo = dataByName[gender][name]
  data = nameInfo.data

  # compute point along path
  step = 0
  for datum in data
    break if yearOf(datum) == year
    step += 1
  stepInput.max = data.length - 1
  stepInput.value = step

  point = data[step]
  percentage = pctgOf(point)

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
  mainChart.drawCircle(point)

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

  closestNames = nameInfo.closestNames?.slice(0,simsInput.value).map (n) ->
    { name: n[1], gender: n[0], values: dataByName[n[0]][n[1]].data }
  closestNames ||= []

  simChart.setScale(currentScale)
  simChart.drawSeries(closestNames)
  if closestNames.length
    simChart.setTitle "#{simsInput.value} names most similar to #{genderSymbol} #{name}"
  else
    simChart.setTitle "Not enough data for #{genderSymbol} #{name} to chart similarities"

window.redraw()

circleDrag = d3.behavior.drag()

circleDrag.on 'dragstart', ->
  mainChart.circle.classed('dragging', true)

circleDrag.on 'drag', ->
  mainChart.arrows.style('display', 'none')
  mainChart.arrows2.style('display', 'none')
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

$('#main-chart-spinner').remove()

window.exclusivelyHispanicBoyNames = [
  "Agustin", "Alberto", "Alejandro", "Alfredo", "Alonso", "Alphonso",
  "Alvaro", "Andres", "Angel", "Armando", "Arturo", "Benito",
  "Camilo", "Carlos", "Carmelo", "Cristobal", "Cruz",
  "Diego", "Domingo", "Eduardo", "Efrain", "Emiliano", "Emilio",
  "Enrique", "Ernesto", "Esteban", "Ezequiel", "Felipe",
  "Fernando", "Francisco", "Gael", "Gerardo", "Gilberto", "Guadalupe", "Guillermo",
  "Gustavo", "Hector", "Heriberto", "Humberto", "Ignacio", "Ismael", "Jaime", "Javier",
  "Jesus", "Joaquin", "Joel", "Jorge", "Josue", "Juan",
  "Lorenzo", "Luciano", "Luis", "Manuel", "Marco", "Mateo",
  "Matias", "Mauricio", "Maximiliano", "Maximo", "Miguel", "Moises",
  "Nathanael", "Noel", "Osvaldo", "Pablo", "Pedro", "Rafael", "Ramiro", "Raul", "Reynaldo", "Ricardo", "Rigoberto",
  "Roberto", "Rodolfo", "Rodrigo", "Rogelio", "Rolando", "Salvador", "Santiago", "Santino", "Sergio",
  "Tomas", "Valentin", "Valentino", "Vicente"
].sort()

window.sharedHispanicBoyNames = [
  "Aaron", "Adrian", "Alan", "Antonio",
  "Axel", "Benjamin", "Bruno", "Christian",
  "Christopher", "Daniel", "Dante", "Damian", "David", "Dylan",
  "Elias", "Emmanuel", "Gabriel", "Hugo", "Ian", "Isaac",
  "Ivan", "Joshua", "Julian", "Kevin", "Leonardo", "Lucas",
  "Mario", "Martin", "Nicolas", "Samuel", "Saul", "Sebastian",
  "Simon", "Victor"
].sort()

$('#shared-hispanic-list').attr('title', "Specifically:\n#{sharedHispanicBoyNames.toSentence()}")

window.$ehbnSelect = $('#exclusively-hispanic-boy-name-select')
for name in exclusivelyHispanicBoyNames
  $ehbnSelect.append("<option value='#{name}' selected>#{name}</option>")

#window.$shbnSelect = $('#shared-hispanic-boy-name-select')
#for name in sharedHispanicBoyNames
  #$shbnSelect.append("<option value='#{name}'>#{name}</option>")

julioChart = new NameChart(document.getElementById('julio-chart'))
julioData = [{ name: 'Julio', gender: 'm', values: dataByName.m.Julio.data }]
count = 24
dataByName.m.Julio.closestNames.slice(0, count).forEach (d) ->
  julioData.push(name: d[1], gender: d[0], values: dataByName[d[0]][d[1]].data)
julioChart.drawSeries(julioData)
julioChart.setTitle("#{count} names most similar to #{genderSymbols.m} Julio")

# data from https://en.wikipedia.org/wiki/Historical_racial_and_ethnic_demographics_of_the_United_States#Historical_data_for_all_races_and_for_Hispanic_origin_.281610.E2.80.932010.29
window.hispanicDemographicData = [
  { totalPopulation: 131670000, hispanicPopulation:  2020000, year: 1940 },
  { totalPopulation: 150700000, hispanicPopulation:  3230000, year: 1950 },
  { totalPopulation: 179320000, hispanicPopulation:  5810000, year: 1960 },
  { totalPopulation: 203210000, hispanicPopulation:  8920000, year: 1970 },
  { totalPopulation: 226550000, hispanicPopulation: 14600000, year: 1980 },
  { totalPopulation: 248710000, hispanicPopulation: 22400000, year: 1990 },
  { totalPopulation: 281420000, hispanicPopulation: 35300000, year: 2000 },
  { totalPopulation: 308750000, hispanicPopulation: 50500000, year: 2010 }
]

hispanicDemographicData.forEach (d) ->
  d.hispanicRatio = d.hispanicPopulation / d.totalPopulation
  d.percentage = 100 * d.hispanicRatio

# Final data point comes from:
#   http://www.pewresearch.org/fact-tank/2015/06/25/u-s-hispanic-population-growth-surge-cools/
hispanicDemographicData.push(year: 2014, percentage: 17.4)

compChart = new NameChart(document.getElementById('hispanic-popularity-vs-population'), {
  sanitizeLine: (l) -> l
  defined: (d) -> pctgOf(d) > 0.01
  yUnits: 'percentage'
  xDomain: [1930, 2020]
  percentageDomain: [0.01, 100]
  height: 395
  legendPlacement: (d, i) ->
    { x: 0.5*@width - 100*i, y: @height + 40 }
})
compChart.setTitle("Hispanic #{genderSymbols.m} Name Popularity vs. Population")

years = [1940..2014]

redrawHispanicComparison = ->
  totalsByYear = {}
  for y in years
    totalsByYear[y] = 0

  #names = ($ehbnSelect.val() || []).concat($shbnSelect.val() || [])
  names = ($ehbnSelect.val() || [])
  for name in names
    data = dataByName['m'][name].data
    for point in data
      if totalsByYear.hasOwnProperty(yearOf(point))
        totalsByYear[yearOf(point)] += pctgOf(point)

  compChart.drawSeries([
    { name: 'Population', values: hispanicDemographicData },
    { name: 'Popularity', values: years.map((y) -> { year: y, percentage: totalsByYear[y] })}
  ])

redrawHispanicComparison()

$ehbnSelect.change redrawHispanicComparison
#$shbnSelect.change redrawHispanicComparison

$('.multiselect-select-all').click ->
  $select = $(@).closest('.multiselect').find('select')
  $select.find('option').prop('selected', true)
  $select.trigger('change').focus()

$('.multiselect-select-none').click ->
  $select = $(@).closest('.multiselect').find('select')
  $select.find('option').prop('selected', false)
  $select.trigger('change').focus()

$('.multiselect select').change ->
  $span = $(@).closest('.multiselect').find('.multiselect-info span')
  values = $(@).val() || []
  if values.length == 1
    $span.text("#{values[0]} selected")
  else
    $span.text("#{values.length} names selected")

$('.multiselect select').trigger('change')

class Chart
  defaultChartWidth: 475
  defaultMarginTop: 30
  defaultMarginLeft: 30
  defaultMarginRight: 0
  defaultMarginBottom: 30
  xUnits: 'year'
  yUnits: 'rank'
  xDomain: [1880, 2014]
  yDomain: [1000, 1]
  x: (d) -> @xScale(d[@xUnits])
  y: (d) -> @yScale(d[@yUnits])
  defined: (d) -> true
  yTickFormat: (d) -> d.toString()
  xTickFormat: (d) -> d.toString()
  sanitizeLine: (line) -> line
  lineColor: '#1f77b4'

  constructor: (element, options) ->
    # extend options
    options ||= {}
    options.margin ||= {}
    options.margin.top ||= @defaultMarginTop
    options.margin.left ||= @defaultMarginLeft
    options.margin.right ||= @defaultMarginRight
    options.margin.bottom ||= @defaultMarginBottom

    this[k] = v for k, v of options

    @defaultChartHeight ||= @defaultChartWidth / 1.618

    @xTickValues ||= (d for d in [@xDomain[0]..@xDomain[1]] by 10)
    @yTickValues ||= [1, 100, 200, 300, 400, 500, 600, 700, 800, 900, 999]
    @height ||= @defaultChartHeight
    @width ||= (@xTickValues.length / 14) * @defaultChartWidth
    @element = element
    @line = d3.svg.line().interpolate('cardinal').x(@x).y(@y).defined(@defined)
    @parentSvg = d3.select(@element).append('svg')
        .attr('width', @width + @margin.left + @margin.right)
        .attr('height', @height + @margin.top + @margin.bottom)
    @svg = @parentSvg.append('g')
        .attr('transform', "translate(#{@margin.left}, #{@margin.top})")
    @xAxisLine = @svg.append('g').attr('class', 'x axis').attr('transform', "translate(0, #{@height})")
    @yAxisLine = @svg.append('g').attr('class', 'y axis')
    @xAxisGrid = @svg.append('g').attr('class', 'x grid')
    @yAxisGrid = @svg.append('g').attr('class', 'y grid')
    @buildXAxis()
    @buildYAxis()
    @innerG = @svg.append('g')
    @outerG = @svg.append('g')
    @setTitle(@title) if @title

  setTitle: (title) ->
    @title = title
    @svg.selectAll('.chart-title').remove()
    @svg.append('text').attr('class', 'chart-title').attr('x', @width / 2).attr('y', 0 - (@margin.top / 2)).attr('text-anchor', 'middle').text(title)

  drawLine: (line) ->
    @svg.selectAll('path.line').remove()
    @innerG.append('path').attr('class', 'line').attr('d', @line(@sanitizeLine(line))).style('stroke', @lineColor).style('fill', 'none')

  drawCircle: (point) ->
    @circle ||= @outerG.append('circle')
      .attr('class', 'marker')
      .attr('r', 8)
    @circle.attr('transform', "translate(#{@x(point)},#{@y(point)})")

  buildYAxis: ->
    @yScale = d3.scale.linear().range([@height, 0]).domain(@yDomain)
    @yAxis = d3.svg.axis().scale(@yScale)
    @yAxisLine.call(@yAxis.tickValues(@yTickValues).tickFormat(@yTickFormat).orient('left'))
    @yAxisGrid.call(@yAxis.ticks(@yTickValues.length).tickFormat('').tickSize(@width, 0).orient('right'))

  buildXAxis: ->
    @xScale = d3.scale.linear().range([0, @width]).domain(@xDomain)
    @xAxis = d3.svg.axis().scale(@xScale)
    @xAxisLine.call(@xAxis.tickValues(@xTickValues).tickFormat(@xTickFormat).orient('bottom'))
    @xAxisGrid.call(@xAxis.ticks(@xTickValues.length).tickFormat('').tickSize(-@height, 0).orient('top'))

class NameChart extends Chart
  defined: (d) -> d.year >= @xDomain[0] and d.year <= @xDomain[1] and (!d.rank || d.rank <= 1000) and d.percentage > 0

  sanitizeLine: (line) ->
    return line if line.length == 1
    return line if line[1].year - line[0].year == 10
    return line if line[1].year - line[0].year == 5
    prevYear = line[0].year - 1
    newLine = []
    for point in line
      newLine.push(year: prevYear + 1, rank: 1001, percentage: 0) unless point.year == prevYear + 1
      newLine.push(point)
      prevYear = point.year
    newLine

  seriesSuffix: (d) ->
    if @combineGenders then d.name else "#{d.gender}-#{d.name}"

  genderColor: (d) ->
    window.genderColors[d.gender]

  percentageTickFormat: (d) =>
    return '' if d == @percentageDomain[0]
    x = Math.log(d) / Math.log(10) + 1e-6
    return '' if Math.abs(x - Math.floor(x)) >= 0.01
    "#{d}%"

  setScale: (units) ->
    @yUnits = units
    if @yUnits == 'percentage'
      @yScale = @percentageScale
      @yAxis = d3.svg.axis().scale(@yScale).orient('left').tickFormat(@percentageTickFormat)
    else
      @yScale = @rankScale
      @yAxis = d3.svg.axis().scale(@yScale).orient('left').tickValues(@yTickValues)
    @yAxisLine.call(@yAxis)
    tickCount = if @yUnits == 'percentage' then 10 else @yTickValues.length
    @yAxis.ticks(tickCount).tickFormat('').tickSize(@width, 0).orient('right')
    @yAxisGrid.call(@yAxis)

  rankDomain: [1000, 1]
  percentageDomain: [0.001, 100]

  buildYAxis: ->
    @rankScale = d3.scale.linear().range([@height, 0]).domain(@rankDomain)
    @percentageScale = d3.scale.log().range([@height, 0]).domain(@percentageDomain)
    @setScale(@yUnits)

  drawVerticalLines: (lines) ->
    @innerG.selectAll('.vertical-line').remove()
    for vertData in lines
      vertLine = @innerG.append("line")
      vertLine
        .attr('class', 'vertical-line')
        .attr('y1', @yScale.range()[0])
        .attr('y2', @yScale.range()[1])
        .attr('x1', @x(vertData))
        .attr('x2', @x(vertData))
      #if @color and vertData.name
        #vertLine.style('stroke', @color(@seriesSuffix(vertData)))

  fixMargins: (i) ->
    maxY = @legendPlacement(undefined, i).y
    @margin.bottom = maxY - @height + 20
    @parentSvg.attr('height', @height + @margin.top + @margin.bottom)

  legendPlacement: (d, i) ->
    vSpace = 20
    vPad = 40
    hPad = @width / 4
    xPos = (hPad * i) % @width
    xRem = (hPad * i) / @width
    xRem = Math.floor(xRem)
    yPos = vPad + @height + vSpace*xRem
    { x: xPos, y: yPos }

  legendClick: ->
    # no-op normally

  drawSeries: (data) ->
    @color = d3.scale.category10()
    @color.domain(data.map (d) => @seriesSuffix(d))
    colorize = (d) => @color(@seriesSuffix(d))

    @fixMargins(data.length)

    hoverIn = (d) =>
      @svg.selectAll('.legend').style('opacity', '0.1')
      @svg.selectAll('.name-line').style('opacity', '0.1')
      @svg.selectAll(".legend-#{@seriesSuffix(d)}").style('opacity', '1')
      @svg.selectAll(".line-#{@seriesSuffix(d)}").style('opacity', '1')

    hoverOut = (d) =>
      @svg.selectAll('.legend').style('opacity', '1')
      @svg.selectAll('.name-line').style('opacity', '1')

    @svg.selectAll('.name-line').remove()

    lines = @svg.selectAll('.name-line').data(data)

    lineEnter = lines.enter().append('g')
      .attr('class', (d) => "name-line line-#{@seriesSuffix(d)}")
      .on('mouseover', hoverIn)
      .on('mouseout', hoverOut)
      .on("click", @legendClick)

    lineEnter.append('path')
      .style('fill', 'none')
      .attr('class', 'line')
      .style('stroke', colorize)
      .attr('d', (d) => @line(@sanitizeLine(d.values)))

    if @combineGenders
      lineEnter.append('path')
        .style('fill', 'none')
        .attr('class', 'line')
        .style('stroke', @genderColor)
        .style('stroke-dasharray', '0,35,10,15')
        .attr('d', (d) => @line(@sanitizeLine(d.values)))

    @svg.selectAll('.legend').remove()

    legend = @svg.selectAll('.legend').data(data)

    legendEnter = legend.enter().append("g")
      .attr('class', (d) => "legend legend-#{@seriesSuffix(d)}")

    legendEnter.append('circle')
      .attr('cx', (d, i) => @legendPlacement(d, i).x)
      .attr('cy', (d, i) => @legendPlacement(d, i).y)
      .attr('r', 7)
      .style('fill', colorize)
      .on("mouseover", hoverIn)
      .on("mouseout", hoverOut)
      .on("click", @legendClick)

    legendEnter.append('text')
      .attr('x', (d, i) => @legendPlacement(d, i).x)
      .attr('y', (d, i) => @legendPlacement(d, i).y)
      .attr('dy', '0.33em')
      .attr('dx', '-0.33em')
      .style('fill', 'white')
      .style('font-size', 'x-small')
      .text((d) -> window.genderSymbols[d.gender])

    legendEnter.append('text')
      .attr('x', (d, i) => @legendPlacement(d, i).x + 10)
      .attr('y', (d, i) => @legendPlacement(d, i).y)
      .attr('dy', '0.33em')
      .style('fill', colorize)
      .text((d) -> d.name)
      .on("mouseover", hoverIn)
      .on("mouseout", hoverOut)
      .on("click", @legendClick)

    if @combineGenders
      legendEnter.append('rect')
        .attr('x', (d, i) => @legendPlacement(d, i).x - 11.5)
        .attr('y', (d, i) => @legendPlacement(d, i).y - 2.5)
        .attr('width', 5)
        .attr('height', 5)
        .style('fill', @genderColor)
        .on("mouseover", hoverIn)
        .on("mouseout", hoverOut)
        .on("click", @legendClick)

window.Chart = Chart
window.NameChart = NameChart
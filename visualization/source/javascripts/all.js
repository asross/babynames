//= require_tree .
//= require d3
//= require jquery
//= require chosen

var genderSelect = document.getElementById('gender');
var nameHeader = document.getElementById('current-name');
var nameSelect = document.getElementById('all-names');
var yearInput = document.getElementById('year');
var rankInput = document.getElementById('rank');
var rangeInput = document.getElementById('name-timeline');

yearInput.value = 1880;
rankInput.value = 1;

rangeInput.oninput = function() {
  data = dataByName[genderSelect.value][nameSelect.value];
  datum = data[this.value - 1];
  yearInput.value = datum.year;
  rankInput.value = datum.rank;
  window.redraw();
};

nameSelect.onchange = function() {
  allNames = Object.keys(dataByName[genderSelect.value]);
  index = allNames.indexOf(this.value);
  if (index >= 0) {
    data = dataByName[genderSelect.value][this.value];
    yearInput.value = data[0].year;
    rankInput.value = data[0].rank;
    window.redraw();
  }
};

$(nameSelect).chosen({ width: '300px' });

genderSelect.onchange = function() {
  nameSelect.innerHTML = "";
  nameOptions = Object.keys(dataByName[this.value]).sort();
  nameOptions.forEach(function(e) {
    option = document.createElement('option');
    option.value = e;
    option.text = e;
    nameSelect.appendChild(option);
  });
  window.redraw();
};

yearInput.onchange = function() {
  window.redraw();
}

rankInput.onchange = function() {
  window.redraw();
}

window.step = function(keyIdentifier) {
  if (keyIdentifier == "Up")        rankInput.stepDown() || rankInput.onchange();
  else if (keyIdentifier == "Down") rankInput.stepUp() || rankInput.onchange();
  else if (keyIdentifier == "Right") yearInput.stepUp() || yearInput.onchange();
  else if (keyIdentifier == "Left") yearInput.stepDown() || yearInput.onchange();
}

document.onkeydown = function() {
  step(event.keyIdentifier);
}

var margin = {top: 20, right: 80, bottom: 30, left: 50},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;
var x = d3.scale.linear().range([0, width]);
var y = d3.scale.linear().range([height, 0]);
x.domain([1880, 2015]);
y.domain([1000, 1]);
var xAxis = d3.svg.axis().scale(x).orient("bottom");
var yAxis = d3.svg.axis().scale(y).orient("left");
var line = d3.svg.line().interpolate("cardinal")
    .x(function(d) { return x(d.year); })
    .y(function(d) { return y(d.rank); })

var svg = d3.select("body").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + height + ")").call(xAxis)
  .append("text").attr("x", width - 40).attr("dy", "1.42em").text("Year");

svg.append("g").attr("class", "y axis").call(yAxis)
  .append("text").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", ".71em").style("text-anchor", "end").text("Ranking");

var xAxisGrid = xAxis.ticks(2015-1880).tickSize(-height, 0).tickFormat('').orient('top');
var yAxisGrid = yAxis.ticks(333).tickSize(width, 0).tickFormat('').orient('right');

svg.append("g").classed('x', true).classed('grid', true).call(xAxisGrid);
svg.append("g").classed('y', true).classed('grid', true).call(yAxisGrid);

var g = svg.append("g");

var circle = g.append("circle")
  .attr("class", "marker")
  .style("stroke", "#1f77b4")
  .style("fill", "#1f77bf")
  .style("r", 5);

window.segmentsOf = function(line) {
  prevYear = line[0].year - 1;
  segments = [];
  currentSegment = []
  for (i = 0; i < line.length; i++) {
    if (line[i].year == prevYear + 1) {
      currentSegment.push(line[i]);
    } else {
      segments.push(currentSegment);
      currentSegment = [line[i]];
    }
    prevYear = line[i].year;
  }
  if (currentSegment.length)
    segments.push(currentSegment);
  return segments;
};

window.redraw = function() {
  var year = yearInput.value;
  var rank = rankInput.value;
  var gender = genderSelect.value;

  var currentNameInfo = dataByYear[gender][year][rank - 1];
  var currentName = currentNameInfo.name;

  nameSelect.value = currentName;
  $(nameSelect).trigger('chosen:updated');

  nameHeader.innerHTML = currentName;

  data = dataByName[gender][currentName];

  rangeInput.max = data.length;
  index = 1;
  for (i = 0; i < data.length; i++) {
    if (data[i].year == year) break;
    index += 1;
  }
  rangeInput.value = index;

  segments = segmentsOf(data);
  d3.selectAll("path.line").remove();
  segments.forEach(function(segment) {
    g.append("path")
    .attr("d", line(segment))
    .attr("class", "line")
    .style("stroke", "#1f77b4")
    .style("fill", "none");
  });

  circle.attr("transform", "translate(" + x(year) +"," + y(rank) + ")");
};

console.log('starting!');
genderSelect.onchange();

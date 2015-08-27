//= require_tree .
//= require d3

window.year = 1880;
window.rank = 0;

var steppers = document.getElementsByClassName('stepper-widget');
var genderSelect = document.getElementById('gender');
var nameHeader = document.getElementById('current-name');
var nameSelect = document.getElementById('all-names');

nameSelect.onchange = function() {
  allNames = Object.keys(dataByName[genderSelect.value]);
  index = allNames.indexOf(this.value);
  if (index >= 0) {
    data = dataByName[genderSelect.value][this.value];
    window.year = data[0][0];
    window.rank = data[0][1] - 1;
    window.redraw();
  }
};

genderSelect.onchange = function() {
  window.redraw();
};

changeQuantity = function(quantity, value) {
  window[quantity] += value;
  try {
    window.redraw();
  } catch(e) {
    window[quantity] -= value;
  };
}

for (i = 0; i < steppers.length; i++) {
  incrementButton = steppers[i].getElementsByClassName('increment')[0];
  decrementButton = steppers[i].getElementsByClassName('decrement')[0];
  incrementButton.onclick = function() {
    quantity = element.parentElement.attributes['data-target'].value;
    changeQuantity(quantity, 1); };
  decrementButton.onclick = function() {
    quantity = element.parentElement.attributes['data-target'].value;
    changeQuantity(quantity, -1); };
};

document.onkeydown = function() {
  if (event.keyIdentifier == "Up") changeQuantity('rank', -1);
  else if (event.keyIdentifier == "Down") changeQuantity('rank', 1);
  else if (event.keyIdentifier == "Right") changeQuantity('year', 1);
  else if (event.keyIdentifier == "Left") changeQuantity('year', -1);
}

var margin = {top: 20, right: 80, bottom: 30, left: 50},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;
var x = d3.scale.linear().range([0, width]);
var y = d3.scale.linear().range([height, 0]);
x.domain([1880, 2015]);
y.domain([1000, 0]);
var xAxis = d3.svg.axis().scale(x).orient("bottom");
var yAxis = d3.svg.axis().scale(y).orient("left");
var dataYear = function(d) { return d[0]; };
var dataPct = function(d) { return d[1]; };
var line = d3.svg.line().interpolate("basis")
    .x(function(d) { return x(dataYear(d)); })
    .y(function(d) { return y(dataPct(d)); })

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

var g = svg.append("g")
var path = g.append("path")
      .attr("class", "line")
      .style("stroke", "#1f77b4")
      .style("fill", "none");

var circle = g.append("circle")
  .attr("class", "marker")
  .style("stroke", "#1f77b4")
  .style("fill", "#1f77bf")
  .style("r", 5);

window.redraw = function() {
  var gender = genderSelect.value;
  var currentNameInfo = dataByYear[gender][year][rank];
  var currentName = currentNameInfo[1];

  var nameOptions = Object.keys(dataByName[gender]).sort();
  nameSelect.innerHTML = "<option>Jump to name...</option>";
  nameOptions.forEach(function(e) {
    option = document.createElement('option');
    option.value = e;
    option.text = e;
    nameSelect.appendChild(option);
  });

  nameHeader.innerHTML = currentName;

  for (i = 0; i < steppers.length; i++) {
    quantity = steppers[i].attributes['data-target'].value;
    header = steppers[i].getElementsByTagName('h2')[0];
    header.innerHTML = window[quantity];
  }

  path.attr("d", line(dataByName[gender][currentName]));
  circle.attr("transform", "translate(" + x(year) +"," + y(rank) + ")");
};

console.log('starting!');
redraw();

//
  //window.babyNameData = <%= baby_name_data %>;
  //window.babyNameRankings = <%= rankings %>;
  //window.gender = 'boy_names';
  //window.year = 1880;
  //window.nameIndex = 0;
  //window.chartContainer = document.getElementsByTagName('body')[0];

  ////var abbreviated_data = {};
  ////var boy_names = Object.keys(window.babyNameData.boy_names);
  ////for (i=0; i<200; i++) {
  ////  name = boy_names[i];
  ////  abbreviated_data[name] = window.babyNameData.boy_names[name];
  ////}
  ////window.babyNameData.boy_names = abbreviated_data;

  //window.redrawEverything = function() {

//allNames = Object.keys(babyNameData[gender]);
//currentName = allNames[nameIndex];

//chartContainer.innerHTML = '';




//selectName = function(name) {
  //var index = allNames.indexOf(name);
  //if (index >= 0) {
    //window.nameIndex = index;
    //redrawEverything();
  //}
//}

//select = document.createElement('select');
//babyNameRankings[gender].forEach(function(e) {
  //option = document.createElement('option');
  //option.value = e[0];
  //option.text = e[0] + " " + e[1];
  //if (e[0] == currentName) option.selected = true;
  //select.appendChild(option);
//});
//chartContainer.appendChild(select);

//nameHeader = document.createElement('h1');
//nameHeader.innerHTML = currentName;
//chartContainer.appendChild(nameHeader);

//select.onchange = function() {
  //selectName(select.value);
//}
//};

////redraw = function(change) {
////  oldEl = document.getElementById(selectedName());
////  i += change;
////  if (i >= allNames.length) i = 0;
////  if (i < 0) i = allNames.length - 1;
////  newEl = document.getElementById(selectedName());
////
////  oldEl.style.opacity = 0.1;
////  newEl.style.opacity = 1;
////  oldEl.children[0].style.strokeWidth = '1.5px';
////  newEl.children[0].style.strokeWidth = '5px';
////};

////document.onkeydown = function(event) {
////  if (event.keyIdentifier == 'Up' || event.keyIdentifier == 'Right') {
////    redraw(1);
////  } else if (event.keyIdentifier == 'Down' || event.keyIdentifier == 'Left') {
////    redraw(-1);
////  }
////}
////select.onchange();
//redrawEverything();

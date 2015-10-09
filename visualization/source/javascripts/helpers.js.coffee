window.genderSymbols = { m: '♂', f: '♀' }
window.genderLabels = { m: 'Boy Names', f: 'Girl Names' }
window.genderStubs = { m: 'boy', f: 'girl' }

window.yearOf = (d) -> d[0]
window.rankOf = (d) -> d[1]
window.pctgOf = (d) -> d[2]

window.roundTo = (closestN, num) ->
  closestN * Math.round(num / closestN)

window.clamp = (n, min, max) ->
  Math.min(Math.max(n, min), max)

Array.prototype.revslice = (min, max) ->
  if min == 0
    this.slice(-max)
  else
    this.slice(-max, -min)

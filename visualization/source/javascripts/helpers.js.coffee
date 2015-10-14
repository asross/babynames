window.genderSymbols = { m: '♂', f: '♀' }
window.genderLabels = { m: 'Boy Names', f: 'Girl Names' }
window.genderStubs = { m: 'boy', f: 'girl' }
window.genderColors = { m: '#25AAE2', f: '#F174AE' }

window.yearOf = (d) -> d.year || d[0]
window.rankOf = (d) -> d.rank || d[1]
window.pctgOf = (d) -> d.percentage || d[2]

window.roundDownTo = (closestN, num) ->
  closestN * Math.floor(num / closestN)

window.roundUpTo = (closestN, num) ->
  closestN * Math.ceil(num / closestN)

window.clamp = (n, min, max) ->
  Math.min(Math.max(n, min), max)

Array.prototype.revslice = (min, max) ->
  if min == 0
    this.slice(-max)
  else
    this.slice(-max, -min)

downloadData = (object, name) ->
  blob = new Blob([JSON.stringify(object)], { type: 'application/json' })
  $a = $('<a></a>')
  $a.css(display: 'none')
  $a.appendTo($('body'))
  $a.attr(
    href: URL.createObjectURL(blob),
    target: '_blank',
    download: "#{name}.json"
  )
  $a[0].click()
  $a.remove()

$('#download-data-by-name').click ->
  downloadData(dataByName, 'us_baby_name_popularity_by_name')

$('#download-data-by-year').click ->
  downloadData(dataByYear, 'us_baby_name_popularity_by_year')

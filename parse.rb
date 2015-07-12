require 'json'

data = { boy_names: {}, girl_names: {} }

1880.upto(2014).each do |year|
  html = File.read("./raw/#{year}.html")
  html.scan(/<tr align="right">(?:\s*<td>[\w,.%]+<\/td>\s*)+<\/tr>/).each do |row|
    rank, boy_name, boy_percent, girl_name, girl_percent = row.scan(/<td>([\w,.%]+)<\/td>/).flatten
    (data[:boy_names][year] ||= []) << [rank, boy_name, boy_percent]
    (data[:girl_names][year] ||= []) << [rank, girl_name, girl_percent]
  end
end

File.open("./data.json", "wb") do |f|
  f.write JSON.dump(data)
end

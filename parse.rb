require 'json'

data_by_year = { boy_names: {}, girl_names: {} }
data_by_name = { boy_names: {}, girl_names: {} }

1880.upto(2014).each do |year|
  html = File.read("./raw/#{year}.html")
  html.scan(/<tr align="right">(?:\s*<td>[\w,.%]+<\/td>\s*)+<\/tr>/).each do |row|
    rank, boy_name, boy_percent, girl_name, girl_percent = row.scan(/<td>([\w,.%]+)<\/td>/).flatten
    rank = rank.to_i
    boy_percent = boy_percent.sub(/%$/, '').to_f
    girl_percent = girl_percent.sub(/%$/, '').to_f

    (data_by_year[:boy_names][year] ||= []) << { rank: rank, name: boy_name, percent: boy_percent }
    (data_by_year[:girl_names][year] ||= []) << { rank: rank, name: girl_name, percent: girl_percent }

    (data_by_name[:boy_names][boy_name] ||= []) << { year: year, rank: rank, percent: boy_percent }
    (data_by_name[:girl_names][girl_name] ||= []) << { year: year, rank: rank, percent: girl_percent }
  end
end

File.open("./data_by_year.json", "wb") do |f|
  f.write JSON.dump(data_by_year)
end

File.open("./data_by_name.json", "wb") do |f|
  f.write JSON.dump(data_by_name)
end

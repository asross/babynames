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

    (data_by_year[:boy_names][year] ||= []) << [rank, boy_name, boy_percent]
    (data_by_year[:girl_names][year] ||= []) << [rank, girl_name, girl_percent]

    (data_by_name[:boy_names][boy_name] ||= []) << [year, rank, boy_percent]
    (data_by_name[:girl_names][girl_name] ||= []) << [year, rank, girl_percent]
  end
end

data_by_name.each do |name_type, name_data|
  name_data.each do |name, counts|
    unless counts.count >= 25
      data_by_name[name_type].delete(name)
    end
  end
end

rankings = { boy_names: [], girl_names: [] }
data_by_name.each do |name_type, name_data|
  name_data.each do |name, counts|
    auc = 0
    counts.each { |c| auc += 1000 - c[1] }
    rankings[name_type] << [name, -auc]
  end
  rankings[name_type].sort_by!(&:last)
end

File.open("./data_by_year.json", "wb") do |f|
  f.write JSON.dump(data_by_year)
end

File.open("./data_by_name.json", "wb") do |f|
  f.write JSON.dump(data_by_name)
end

File.open("./rankings.json", "wb") do |f|
  f.write JSON.dump(rankings)
end

require 'json'
require 'pry'

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

def decade(data)
  data[:year].to_s[0..2].to_i
end

def average_by(key, array)
  return 1000 unless array.length > 0
  sum = array.reduce(0) { |running_total, element| running_total += element[key] }
  sum.to_f / array.length
end

CHANGE_TOLERANCE = 50

metrics_by_name = { boy_names: {}, girl_names: {} }
metrics_by_name.each do |gender, metrics|
  data_by_name[gender].each do |name, data|
    data_by_decade = {}
    188.upto(201).each { |i| data_by_decade[i] = [] }
    data.each do |datum|
      data_by_decade[decade(datum)] << datum
    end

    averages_by_decade = data_by_decade.map { |decade, points| {
      decade: decade * 10,
      average_rank: average_by(:rank, points),
      average_percent: average_by(:percent, points)
    }}

    changes_by_decade = []
    prev_decade = averages_by_decade[0]
    averages_by_decade[1..-1].each do |this_decade|
      changes_by_decade << {
        from: prev_decade[:decade],
        to: this_decade[:decade],
        change: this_decade[:average_rank] - prev_decade[:average_rank]
      }
      prev_decade = this_decade
    end


    decay_profile = changes_by_decade.map { |c|
      case
      when c[:change] < -CHANGE_TOLERANCE*3
        3 #:getting_much_more_popular
      when c[:change] > CHANGE_TOLERANCE*3
        -3 #:getting_much_less_popular
      when c[:change] < -CHANGE_TOLERANCE
        1 #:getting_more_popular
      when c[:change] > CHANGE_TOLERANCE
        -1 #:getting_less_popular
      else
        0 #:stable
      end
    }

    max = averages_by_decade.max_by { |el| el[:average_rank] }
    min = averages_by_decade.min_by { |el| el[:average_rank] }

    total_spread = max[:average_rank] - min[:average_rank]
    normalized_changes_by_decade = changes_by_decade.map { |cd| {
      from: cd[:from],
      to: cd[:to],
      change: cd[:change] / total_spread.to_f
    }}

    first = nil
    last = nil
    averages_by_decade.each do |avg|
      if avg[:average_rank] < 1000
        last = avg
        first ||= avg
      end
    end

    metrics[name] = {
      name: name,
      averages_by_decade: averages_by_decade,
      changes_by_decade: changes_by_decade,
      normalized_changes_by_decade: normalized_changes_by_decade,
      decay_profile: decay_profile,
      max: max,
      min: min,
      initial: first,
      final: last,
      overall: average_by(:average_rank, averages_by_decade)
    }

  end
end



def distance_between_profiles(m1, m2)
  distance = 0
  i = 0
  m1[:decay_profile].zip(m2[:decay_profile]).each do |action1, action2|
    i += 1
    next if i == 1
    distance += (action1 - action2).abs
    #if action1 == action2
      #distance += 0
    #elsif action1 == :stable || action2 == :stable
      #distance += 1
    #else
      #distance += 2
    #end
  end
  distance
end

#def distance_between_changes(m1, m2)
  #total = 0
  #m1[:normalized_changes_by_decade].zip(m2[:normalized_changes_by_decade]).each do |change1, change2|
    #total += (change1[:change] - change2[:change]).abs
  #end
  #total / m1[:normalized_changes_by_decade].to_f
#end

groups_by_gender = { boy_names: [], girl_names: [] }

groups_by_gender.each do |gender, groups|
  metrics = metrics_by_name[gender].values
  popular_names = metrics.select { |m| m[:overall] < 500 }
  popular_names.each do |name|
    matching_group = groups.detect do |group|
      average_distance = 0
      group.each do |item|
        average_distance += distance_between_profiles(item, name)
      end
      average_distance = average_distance / group.length.to_f
      average_distance <= 4
    end
    if matching_group
      matching_group << name
    else
      groups << [name]
    end
  end
  groups.select!{|g| g.length >= 5}
  groups.map{|g| g.map{|gg| gg[:name] }}.each {|row| print row; print "\n************\n"}; nil
end


File.open("./data_by_year.json", "wb") do |f|
  f.write JSON.dump(data_by_year)
end

File.open("./data_by_name.json", "wb") do |f|
  f.write JSON.dump(data_by_name)
end

File.open("./metrics_by_name.json", "wb") do |f|
  f.write JSON.dump(metrics_by_name)
end

File.open("./groups.json", "wb") do |f|
  f.write JSON.dump(groups_by_gender)
end

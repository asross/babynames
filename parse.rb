require 'json'
require 'pry'

module Enumerable
  def sum
    self.inject(0){|accum, i| accum + i }
  end

  def mean
    self.sum/self.length.to_f
  end

  def sample_variance
    m = self.mean
    sum = self.inject(0){|accum, i| accum +(i-m)**2 }
    sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end
end

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

def elementwise_average(array_of_arrays)
  array_of_arrays[0].zip(*array_of_arrays[1..-1]).map(&:mean)
end

CHANGE_TOLERANCE = 50

#metrics_by_decade = Hash.new{|h,k| h[k] = [] }

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
      #metrics_by_decade["#{prev_decade[:decade]}-#{this_decade[:decade]}"] << this_decade[:average_rank] - prev_decade[:average_rank]
      changes_by_decade << {
        from: prev_decade[:decade],
        to: this_decade[:decade],
        change: this_decade[:average_rank] - prev_decade[:average_rank]
      }
      prev_decade = this_decade
    end


    decay_profile = changes_by_decade.map { |c|
      number = 0
      [3, 2, 1, 0.5, 0.25].each do |n|
        break if number != 0
        if c[:change] < -CHANGE_TOLERANCE*n
          number = n*1.5
        elsif c[:change] > CHANGE_TOLERANCE*n
          number = -n*1.5
        end
      end
      number
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
  m1.zip(m2).each do |action1, action2|
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
        average_distance += distance_between_profiles(item[:decay_profile], name[:decay_profile])
      end
      average_distance = average_distance / group.length.to_f
      average_distance <= 3
    end
    if matching_group
      matching_group << name
    else
      groups << [name]
    end
  end

  done = false

  until done
    done = true
    combinations_this_time = []

    groups.each_with_index do |group1, i|
      avg1 = elementwise_average(group1.map{|g|g[:decay_profile]})
      next if combinations_this_time.any?{|combo| combo.include?(i) }
      groups.each_with_index do |group2, j|
        next if i == j
        next if combinations_this_time.any?{|combo| combo.include?(j) }
        avg2 = elementwise_average(group2.map{|g|g[:decay_profile]})

        if distance_between_profiles(avg1, avg2) <= 7
          done = false
          combinations_this_time << [i, j]
        end
      end
    end

    combinations_this_time.each do |i, j|
      groups[i] += groups[j]
    end
    indexes_to_delete = combinations_this_time.map(&:last).sort.reverse
    indexes_to_delete.each do |j|
      groups.delete_at(j)
    end
  end

  #groups_with_distances = groups.map{|group| [group, elementwise_average(group.map{|g|g[:decay_profile]})] }

  #intragroup_distances.each do |group1|
    #puts '********'
    #intragroup_distances.each do |group2|
      #print distance_between_profiles(group1, group2)
      #print "\n"
    #end
  #end
  #binding.pry
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

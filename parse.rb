require 'json'
require 'set'
require 'pry'

module Enumerable
  def average_by(key, default)
    return default if self.length == 0
    total = self.inject(0) do |accum, element|
      accum += element[key]
    end
    total / length.to_f
  end

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

def changes(list, time_key, value_key)
  prev_period = list[0]
  list[1..-1].each_with_object([]) do |this_period, results|
    results << {
      from: prev_period[time_key],
      to: this_period[time_key],
      change: this_period[value_key] - prev_period[value_key]
    }
    prev_period = this_period
  end
end

def decay_profile(trend, bin_size = 30, importance = 1.5)
  trend.map do |c|
    number = 0
    [3, 2, 1, 0.5, 0.25].each do |n|
      break if number != 0
      if c[:change] < -bin_size*n
        number = n*importance
      elsif c[:change] > bin_size*n
        number = -n*importance
      end
    end
    number
  end
end

def distance_between_change_summaries(m1, m2)
  distance = 0
  m1.zip(m2).each do |action1, action2|
    distance += Math.sqrt (action1 - action2).abs
  end
  distance
end

def distance_between_averages(m1, m2)
  distance = 0
  m1.zip(m2).each do |action1, action2|
    distance += Math.sqrt (action1[:rank] - action2[:rank]).abs
  end
  distance
end

data_by_year = { m: {}, f: {} }
data_by_name = { m: {}, f: {} }
decades = 188.upto(201).to_a
fiveyrs = 376.upto(402).to_a

# parse the HTML tables scraped from ssa.gov to get the data in a form we can use.
# Store it both by name and by year for easy lookup.
1880.upto(2014).each do |year|
  html = File.read("./raw/#{year}.html")
  html.scan(/<tr align="right">(?:\s*<td>[\w,.%]+<\/td>\s*)+<\/tr>/).each do |row|
    rank, boy_name, boy_percent, girl_name, girl_percent = row.scan(/<td>([\w,.%]+)<\/td>/).flatten
    rank = rank.to_i
    boy_percent = boy_percent.sub(/%$/, '').to_f
    girl_percent = girl_percent.sub(/%$/, '').to_f

    (data_by_year[:m][year] ||= []) << { rank: rank, name: boy_name, percentage: boy_percent }
    (data_by_year[:f][year] ||= []) << { rank: rank, name: girl_name, percentage: girl_percent }

    (data_by_name[:m][boy_name] ||= []) << { year: year, rank: rank, percentage: boy_percent }
    (data_by_name[:f][girl_name] ||= []) << { year: year, rank: rank, percentage: girl_percent }
  end
end

# compute some metrics about the data (such as smoothed averages, changes over time, etc)
metrics_by_name = { m: {}, f: {} }
metrics_by_name.each do |gender, metrics|
  data_by_name[gender].each do |name, data|
    m = {}
    m[:name] = name
    m[:data] = data

    # compute some five-year and ten-year averages;
    # this can be displayed as smoothed data or used
    # in calculating similarity.
    ten_year_data = Hash[decades.map { |i| [i, []] }]
    five_year_data = Hash[fiveyrs.map { |i| [i, []] }]
    area_under_curve = 0 # also compute the area under the curve, so we can rank overall popularity over the whole period

    data.each do |d|
      area_under_curve += 1000 - d[:rank]
      ten_year_data[d[:year]/10] << d
      five_year_data[d[:year]/5] << d
    end

    m[:area_under_curve] = area_under_curve

    ten_year_averages = ten_year_data.map { |yr, points| {
      year: 10*yr,
      rank: points.average_by(:rank, 1000),
      percentage: points.average_by(:percentage, 0)
    }}

    five_year_averages = five_year_data.map { |yr, points| {
      year: 5*yr,
      rank: points.average_by(:rank, 1000),
      percentage: points.average_by(:percentage, 0)
    }}

    m[:ten_year_averages] = ten_year_averages
    m[:five_year_averages] = five_year_averages

    # now compute the derivatives; by how much did the popularity
    # change each decade/five-year-period?
    ten_year_changes = changes(ten_year_averages, :year, :rank)
    five_year_changes = changes(five_year_averages, :year, :rank)
    m[:ten_year_changes] = ten_year_changes
    m[:five_year_changes] = five_year_changes

    # also precompute a simplified version of the changes, with bucketed
    # increments. This will let us consider as similar names that change
    # by different amounts but in the same direction.
    m[:ten_year_change_summary] = decay_profile(ten_year_changes)
    m[:five_year_change_summary] = decay_profile(five_year_changes)
    m[:closest_names] = []

    metrics[name] = m
  end
end

# now compute closest names -- but only for names that are reasonably popular,
# because you have to compare every name to every other, which grows like n^2
all_metrics = []
all_metrics += metrics_by_name[:m].map{|name, metrics| [:m, metrics] }
all_metrics += metrics_by_name[:f].map{|name, metrics| [:f, metrics] }
all_metrics.select!{|g, metrics| metrics[:area_under_curve] > 20000 }

# compute both the distance between their (simplified) changes
# and the distance between their actual popularities, smoothed over decades.
# Then compute the version of distance we will use as a weighted
# average of both of those distances. Store the most similar 100 names.
ckey = :ten_year_change_summary
akey = :ten_year_averages
all_metrics.each do |gender1, metric1|
  closest = SortedSet.new
  all_metrics.each do |gender2, metric2|
    next if gender1 == gender2 && metric1[:name] == metric2[:name]
    distance1 = distance_between_change_summaries(metric1[ckey], metric2[ckey])
    distance2 = distance_between_averages(metric1[akey], metric2[akey])
    distance = 0.7*distance1 + 0.3*distance2
    closest << [distance, gender2, metric2[:name]]
  end
  metric1[:closest_names] = closest.to_a[0..100]
end

# delete what we don't need so the payload is smaller
metrics_by_name.each do |gender, mbn|
  mbn.each do |name, metrics|
    metrics.delete(:ten_year_changes)
    metrics.delete(:ten_year_change_summary)
    metrics.delete(:five_year_changes)
    metrics.delete(:five_year_change_summary)
  end
end

# write it out to a JSON file
File.open("./data_by_year.json", "wb") do |f|
  f.write JSON.dump(data_by_year)
end

File.open("./data_by_name.json", "wb") do |f|
  f.write JSON.dump(metrics_by_name)
end

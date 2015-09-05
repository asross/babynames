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

def decay_profile(trend, bin_size = 50, importance = 1.5)
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

decades = 188.upto(201).to_a
fiveyrs = 376.upto(402).to_a

metrics_by_name = { boy_names: {}, girl_names: {} }
metrics_by_name.each do |gender, metrics|
  data_by_name[gender].each do |name, data|
    m = {}
    m[:name] = name

    ten_year_data = Hash[decades.map { |i| [i, []] }]
    five_year_data = Hash[fiveyrs.map { |i| [i, []] }]
    area_under_curve = 0

    data.each do |d|
      area_under_curve += 1000 - d[:rank]
      ten_year_data[d[:year]/10] << d
      five_year_data[d[:year]/5] << d
    end

    m[:area_under_curve] = area_under_curve

    ten_year_averages = ten_year_data.map { |yr, points| { year: 10*yr, rank: points.average_by(:rank, 1000) } }
    five_year_averages = five_year_data.map { |yr, points| { year: 5*yr, rank: points.average_by(:rank, 1000) } }

    m[:ten_year_averages] = ten_year_averages
    m[:five_year_averages] = five_year_averages

    ten_year_changes = changes(ten_year_averages, :year, :rank)
    five_year_changes = changes(five_year_averages, :year, :rank)

    m[:ten_year_changes] = ten_year_changes
    m[:five_year_changes] = five_year_changes

    m[:ten_year_change_summary] = decay_profile(ten_year_changes)
    m[:five_year_change_summary] = decay_profile(five_year_changes)

    m[:closest_names] = []

    metrics[name] = m
  end
end


def distance_between_change_summaries(m1, m2)
  distance = 0
  m1.zip(m2).each do |action1, action2|
    distance += (action1 - action2).abs
  end
  distance
end

all_metrics = []
all_metrics += metrics_by_name[:boy_names].map{|name, m| [:boy_names, m] }
all_metrics += metrics_by_name[:girl_names].map{|name, m| [:girl_names, m] }
all_metrics.select!{|g, m| m[:area_under_curve] > 50000 }

all_metrics.each do |_, metric1|
  closest = SortedSet.new
  all_metrics.each do |gender, metric2|
    distance = distance_between_change_summaries(metric1[:five_year_change_summary], metric2[:five_year_change_summary])
    closest << [distance, gender, metric2[:name]]
  end
  metric1[:closest_names] = closest.to_a[0..100]
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

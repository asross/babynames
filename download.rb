1880.upto(2016).each do |year|
  File.open("./raw/#{year}.html", "wb") do |f|
    f.write `curl --data "number=p&top=1000&year=#{year}" https://www.ssa.gov/cgi-bin/popularnames.cgi`
  end
end

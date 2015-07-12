1880.upto(2014).each do |year|
  File.open("./raw/#{year}.html", "wb") do |f|
    f.write `curl --data "number=p&top=1000&year=#{year}" http://www.ssa.gov/cgi-bin/popularnames.cgi`
  end
end

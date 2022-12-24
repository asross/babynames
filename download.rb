1880.upto(2021).each do |year|
  fname = "./raw/#{year}.html"

  if File.exists?(fname)
    text = File.read(fname)
    if text.include?("total males")
      puts "already downloaded: #{year}"
      next
    end
  end

  puts "need to download #{year}"

  File.open("./raw/#{year}.html", "wb") do |f|
    f.write `curl --data "number=p&top=1000&year=#{year}&token=Submit" https://www.ssa.gov/cgi-bin/popularnames.cgi`
  end

  sleep 1
end

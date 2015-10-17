# Popular Baby Names in the US, 1880-2014

This repo is for a data visualization of baby name popularity from the [US Office of Social Security](http://www.ssa.gov/oact/babynames). It contains the code necessary to scrape/parse the baby name popularity data from the ssa.gov website, analyze and augment it with extra features like similar names, and then expose it as a webpage with charts using [d3](http://d3js.org).

## To Get The Data

The easiest way to get the data is to go to the [visualization website](http://babyname-visualization.s3-website-us-east-1.amazonaws.com) and download it using the links at the very end of the page. That way, you will be able to get it as JSON in a hopefully convenient format. If you'd like to generate it all from scratch, though, you can clone this repository, run `ruby download.rb` (assuming you have [Ruby](https://www.ruby-lang.org) and [curl](http://curl.haxx.se/) installed), and it will re-download the data by scraping the Office of Social Security's website. Then you can run `ruby parse.rb`, which will parse those HTML pages, compute the closest names, and then compress everything into a format optimized for sending to the browser. At that point, you can `cd` into `visualization/` and run the visualization [Middleman app](https://middlemanapp.com/) to see it in your local browser.

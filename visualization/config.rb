###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end
set :haml, { :ugly => true, :format => :html5 }

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (https://middlemanapp.com/advanced/dynamic_pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

sprockets.append_path File.join root, 'bower_components'

sprockets.import_asset 'd3/d3'

sprockets.import_asset 'chosen/chosen-sprite@2x.png' do |p|
  "stylesheets/chosen-sprite@2x.png"
end

sprockets.import_asset 'bootstrap/fonts/glyphicons-halflings-regular.woff' do |p|
  "#{fonts_dir}/glyphicons-halflings-regular.woff"
end

sprockets.import_asset 'bootstrap/fonts/glyphicons-halflings-regular.woff2' do |p|
  "#{fonts_dir}/glyphicons-halflings-regular.woff2"
end

helpers do
  def data_by_year
    File.read("#{root}/../data_by_year.json")
  end

  def closest_names
    File.read("#{root}/../closest_names.json")
  end

  def name_dictionary
    File.read("#{root}/../name_dictionary.json")
  end
end

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Enable cache buster
  # activate :asset_hash

  # Use relative URLs
  activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end

Dotenv.load

if ENV.key?('S3_BUCKET')
  activate :s3_sync do |s3_sync|
    s3_sync.bucket                     = ENV['S3_BUCKET']
    s3_sync.region                     = ENV['S3_REGION']
    s3_sync.aws_access_key_id          = ENV['AWS_ACCESS_KEY_ID']
    s3_sync.aws_secret_access_key      = ENV['AWS_SECRET_ACCESS_KEY']
    s3_sync.delete                     = false # We delete stray files by default.
    s3_sync.after_build                = false # We do not chain after the build step by default.
    s3_sync.prefer_gzip                = true
    s3_sync.path_style                 = true
    s3_sync.reduced_redundancy_storage = false
    s3_sync.acl                        = 'public-read'
    s3_sync.encryption                 = false
    s3_sync.version_bucket             = false
  end
end

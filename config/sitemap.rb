# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://libraries.io"
# pick a place safe to write the files
SitemapGenerator::Sitemap.public_path = 'tmp/'
# store on S3 using Fog
SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new
# inform the map cross-linking where to find the other maps
SitemapGenerator::Sitemap.sitemaps_host = "http://#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com/"
# pick a namespace within your bucket to organize your maps
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

SitemapGenerator::Sitemap.create do
  puts "Generating Projects"
  Project.find_each do |project|
    add project_path(project.to_param), :lastmod => project.updated_at
    add project_dependents_path(project.to_param), :lastmod => project.updated_at
  end

  Version.includes(:project).find_each do |version|
    next if version.project.nil?
    add version_path(version.to_param), :lastmod => version.project.updated_at
  end

  puts "Generating Users"
  GithubUser.find_each do |user|
    add user_path(user), :lastmod => user.updated_at
  end

  puts "Generating Platforms"
  add platforms_path, :priority => 0.7, :changefreq => 'daily'
  Download.platforms.each do |platform|
    name = platform.to_s.demodulize
    add platform_path(name.downcase), :lastmod => Project.platform(name).order('updated_at DESC').first.try(:updated_at)
  end

  puts "Generating Licenses"
  add licenses_path, :priority => 0.7, :changefreq => 'daily'
  Project.popular_licenses(:facet_limit => 120).each do |license|
    name = license.term
    add license_path(name), :lastmod => Project.license(name).order('updated_at DESC').first.try(:updated_at)
  end

  puts "Generating Languages"
  add languages_path, :priority => 0.7, :changefreq => 'daily'
  Project.popular_languages(:facet_limit => 120).each do |language|
    name = language.term
    add language_path(name), :lastmod => Project.language(name).order('updated_at DESC').first.try(:updated_at)
  end
end

require 'rss'
require 'docker'
require 'json'
require 'aws-sdk-ecr'
require 'base64'
require 'jimuguri'
require './lib/build'
require './lib/delivery'

class Rubild
  def run
    app = Cli.new(name: 'rubild', description: 'Ruby installed amazonlinux docker image.', version: '0.0.1')
    app.add_action 'version', 'print version' do
      version
    end

    app.add_action 'versions', 'print released ruby version' do
      output = versions
      puts output.join("\n")
    end

    app.add_action 'tags', 'print registered ruby container images version' do
      output = tags(app.options[:repo])
      puts output.join("\n")
    end

    app.add_action 'diff', 'print the difference between released ruby version and registered ruby version' do
      output = diff(versions, tags(app.options[:repo]))
      puts output
    end

    app.add_action 'build', 'build ruby container images' do
      exit 0 if app.options[:ver].nil?
      build(app.options[:repo], app.options[:ver])
    end

    app.add_option 'r [repository name]', 'repo [repository name](required)', 'specify docker image repository name'
    app.add_option 'n', 'ver [ruby version number](required)', 'specify ruby version number (ex. 2.5.7)'

    app.run ARGV
  end

  def version
    puts '0.0.1'
  end

  def versions
    # 直近の Ruby Version を取得
    url = 'https://www.ruby-lang.org/en/feeds/news.rss'
    rss = RSS::Parser.parse(url)
    versions = []
    rss.channel.items.each do|x|
      versions << x.title.split[-2] if x.title.include?('Released')
    end
    
    versions
  end

  def tags(repo)
    # ECR に登録済みの Docker イメージのタグを取得 (基本的に Ruby バージョン番号がタグになっている)
    resp = Aws::ECR::Client.new.list_images({
      repository_name: repo, 
    })
    tags = resp.image_ids.map { |image| image.image_tag }.compact
    
    tags
  end

  def build(repo, ver)
    params = build_params(repo, ver)
    Build.execute(params)
    build_image = Build.image(params['build_tag'])
    Delivery.execute(build_image, params) if build_image
  end

  def diff(versions, tags)
    difference = versions - tags
    return nil if difference.empty?
    difference.join("\n")
  end

  def minor_ver(ver)
    ver_a = ver.split('.')
    ver_a.delete_at(-1)
    ver_a.join('.')
  end

  def build_params(repo, ver)
    m_ver = minor_ver(ver)
    params = {}
    params['repo'] = repo
    params['ver'] = ver
    params['build_tag'] = "#{repo}:#{ver}"
    params['ruby_download_url'] = "https://cache.ruby-lang.org/pub/ruby/#{m_ver}/ruby-#{ver}.tar.gz"
    params
  end

  Rubild.new.run 
end

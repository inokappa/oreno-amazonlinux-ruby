class Build
  def self.execute(params)
    # Docker Build する際のパラメータを生成
    build_params = { 'nocach' => true,
                     't' => params['build_tag'],
                     'buildargs' => { 'RUBY_VER' => params['ver'],
                                      'RUBY_DOWNLOAD_URL' => params['ruby_download_url'] }.to_json }  
    
    # Docker Build
    Docker::Image.build_from_dir('.', build_params) do |v|
      begin
        log = JSON.parse(v)
      rescue
        log = { 'stream' => 'JSON Log parse Error' }
      end
    
      $stdout.puts log['stream'] if log.has_key?('stream')
    end
  end

  def self.image(image_name)
    build_image = Docker::Image.all.detect do |image|
      image.info['RepoTags'].include?(image_name) unless image.info['RepoTags'].nil?
    end
    build_image
  end
end

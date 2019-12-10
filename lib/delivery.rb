class Delivery
  def self.execute(build_image, params)
    # aws ecr get-login --no-include-email --region ap-northeast-1 相当
    res = Aws::ECR::Client.new.get_authorization_token
    # username, password, server を取得
    u = Base64.decode64(res.authorization_data[-1].authorization_token).split(':')[0]
    pw = Base64.decode64(res.authorization_data[-1].authorization_token).split(':')[-1]
    sv = res.authorization_data[-1].proxy_endpoint

    login!(u, pw, sv)

    params['sv'] = sv
    build_image = attach_tag(build_image, params)
    # Docker Push
    build_image.push do |v|
      begin
        log = JSON.parse(v)
      rescue
        log = v.to_s
      end
      
      $stdout.puts log
    end
  end

  def self.login!(u, pw, sv)
    # Docker Login
    credentials = { 'username' => u, 'password' => pw, 'serveraddress' => sv, 'email' => 'none' }
    Docker.authenticate!(credentials)
  end
  
  def self.attach_tag(build_image, params)
    # Tagged Image
    repo_url = params['sv'].gsub!(/https:\/\/|http:\/\//, '') + '/' + params['repo']
    repo_url_with_tag = repo_url + ':' + params['ver']
    build_image.tag('repo' => repo_url, 'tag' => params['ver'])
    build_image = Docker::Image.all.detect do |image|
      repo_url_with_tag == image.info['RepoTags'].first unless image.info['RepoTags'].nil?
    end
    build_image
  end
end

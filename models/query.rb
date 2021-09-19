class Query
  attr_reader :name, :query, :search_id, :status, :server, :result

  def initialize(query)
    @query = query
    #@completed = false
  end

  def execute
    uri = URI("#{Config.global.host}/api/ariel/searches")
    req = Net::HTTP::Post.new(uri)
    req['SEC'] = Config.global.security_token
    req['Version'] = Config.global.api_version
    req['Accept'] = "application/json"
    req["Content-Type"] = "application/json"
    req.set_form_data('query_expression' => @query)
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    data = JSON.parse(res.body)
    @search_id = data["search_id"]
    @status = data["status"]
  end

  def update_status
    if @status == "EXECUTE"
      uri = URI("#{Config.global.host}/api/ariel/searches/#{@search_id}")
      req = Net::HTTP::Get.new(uri)
      req['SEC'] = Config.global.security_token
      req['Version'] = Config.global.api_version
      req['Accept'] = "application/json"
      req["Content-Type"] = "text/plain"
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
        http.request(req)
      }
      data = JSON.parse(res.body)
      @status = data["status"]
    end
  end

  def get_result
    self.execute if status.nil?
    tick = 0
    while true
      break if tick > 200
      self.update_status
      break if @status != "EXECUTE"
      sleep(40)
      tick += 1
    end
    #print @status
    uri = URI("#{Config.global.host}/api/ariel/searches/#{@search_id}/results")
    req = Net::HTTP::Get.new(uri)
    req['SEC'] = Config.global.security_token
    req['Version'] = Config.global.api_version
    req['Accept'] = "application/json"
    req["Content-Type"] = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    data = JSON.parse(res.body)
    @result = data["events"]
  end

end
class Offense
  attr_accessor :id, :description_en, :description_tr, :magnitude, :severity, :relevance, :credibility, :status
  attr_accessor :domain_id, :domain_name, :offense_source, :offense_type_name, :offense_type_id, :flow_count, :event_count, :categories, :link
  attr_accessor :start_time_tr, :start_time_en, :last_updated_time_tr, :last_updated_time_en
  attr_accessor :events, :rule_ids, :first_event, :event_description

  def initialize(offense_id)
    uri = URI("#{Config.global.host}/api/siem/offenses/#{offense_id}")
    req = Net::HTTP::Get.new(uri)
    req['SEC'] = Config.global.security_token
    req['accept'] = "application/json"
    req['Version'] = Config.global.api_version
    req["Content-Type"] = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    of = JSON.parse(res.body)
    @id = of["id"]
    @description_en = of["description"]
    @description_tr = OffenseController.turkce(of["description"])
    @magnitude = of["magnitude"]
    @severity = of["severity"]
    @relevance = of["relevance"]
    @credibility = of["credibility"]
    @status = of["status"]
    @domain_id = of["domain_id"]
    @domain_name = get_domain
    @offense_source = of["offense_source"]
    @offense_type_id = of["offense_type"]
    @offense_type_name = get_offense_type
    @flow_count = of["flow_count"]
    @event_count = of["event_count"]
    @categories = of["categories"]
    @rule_ids = of["rules"]
    @link = "#{Config.global.url_host}/console/do/sem/offensesummary?appName=Sem&pageId=OffenseSummary&summaryId=#{@id}"
    @start_time_tr = Time.strptime(of["start_time"].to_s, "%Q").localtime.strftime("%d.%m.%Y %H:%M:%S")
    @start_time_en = Time.strptime(of["start_time"].to_s, "%Q").localtime.strftime("%Y-%m-%d %H:%M:%S")
    @last_updated_time_tr = Time.strptime(of["last_updated_time"].to_s, "%Q").localtime.strftime("%d.%m.%Y %H:%M:%S")
    @last_updated_time_en = (Time.strptime(of["last_updated_time"].to_s, "%Q") + 10).localtime.strftime("%Y-%m-%d %H:%M:%S")
  end

  def get_binding
    binding
  end

  def get_offense_type
    unless Config.otm[@offense_type_id].nil?
      return Config.otm[@offense_type_id]
    end
    uri = URI("#{Config.global.host}/api/siem/offense_types/#{@offense_type_id}")
    req = Net::HTTP::Get.new(uri)
    req['SEC'] = Config.global.security_token
    req['Version'] = Config.global.api_version
    req['accept'] = "application/json"
    req["Content-Type"] = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    get_offense_type = JSON.parse(res.body)["name"]
  end

  def get_domain
    return "Default Domain" if @domain_id == 0 or @domain_id.nil?
    uri = URI("#{Config.global.host}/api/config/domain_management/domains/#{@domain_id}")
    req = Net::HTTP::Get.new(uri)
    req['SEC'] = Config.global.security_token
    req['Version'] = Config.global.api_version
    req['accept'] = "application/json"
    req["Content-Type"] = "application/json"

    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    get_domain = JSON.parse(res.body)["name"]
  end

  def get_events
    q = Query.new("select qidname(qid) as \"Event Name\",dateformat(starttime,'dd.MM.yyyy k:mm:ss') as \"Start Time\",
                        logsourcename(logsourceid) AS \"Log Source\",sourceip as \"Source IP\",sourceport as \"Source Port\",
                        destinationip as \"Destination IP\",destinationport as \"Destination Port\",
                        username as \"User Name\",eventcount as \"Event Count\" from events where inoffense(#{@id})
                        order by starttime limit #{Config.global.event_count} start '#{@start_time_en}' stop '#{@last_updated_time_en}' ")
    #print q.query, "\n"
    r = q.get_result
    @events = Array.new
    @events.push r.first.keys unless r.nil?
    @events += r.map(&:values) unless r.nil?
  end

  def get_first_event
    q = Query.new("select UTF8(payload) as \"Payload\" from events where inoffense(#{@id})
                        order by starttime limit 1 start  '#{@start_time_en}' stop '#{@last_updated_time_en}' ")
    #print q.query, "\n"
    r = q.get_result
    @first_event = r.map(&:values).join("") unless r.nil?
  end

  def get_event_description
    q = Query.new("select UTF8(payload) as \"Payload\" from events where inoffense(#{@id}) and devicetype=18
                        order by starttime limit 1 start  '#{@start_time_en}' stop '#{@last_updated_time_en}' ")
    #print q.query, "\n"
    r = q.get_result
    @event_description = r.map(&:values).join("") unless r.nil?
    @event_description = @event_description.strip.gsub("\n", "</br>").gsub("\t", " -> ")
  end

  def render
    if Config.global.domains[self.domain_name].nil?
      receiver = Config.global.domains["Default Domain"]["receiver"].join(",")
    else
      receiver = Config.global.domains[self.domain_name]["receiver"].join(",")
    end
    renderer = ERB.new(File.read("#{Config.global.root}/views/offense.erb"))
    content = renderer.result(binding).gsub("\'", "\"")
    File.write("test.html", content)
    risk = ""
    if self.magnitude.to_i >= Config.global.risk_magnitude
      risk = "!! Risky "
    end
    komut = "(echo 'To: #{ receiver}'
echo 'From: #{Config.global.sender}'
echo 'Subject: #{risk}#{Config.global.subject}'
echo 'Content-Type: text/html'
echo;
echo '#{content}' ) | sendmail -t"
    begin
      #print komut
      `#{komut}`
    rescue
      print "mail error"
    end
  end

  def self.get_last_offenses(last)
    uri = URI("#{Config.global.host}/api/siem/offenses?filter=id%20%3E%20#{last}")
    req = Net::HTTP::Get.new(uri)
    req['SEC'] = Config.global.security_token
    req['accept'] = "application/json"
    req['Version'] = Config.global.api_version
    req["Content-Type"] = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    get_last_offenses = JSON.parse(res.body)
    get_last_offenses = get_last_offenses.map { |o| o["id"] }.sort
  end

  def self.set_offense(offense_id)
    uri = URI("#{@host}/api/siem/offenses/#{offense_id}")
    req = Net::HTTP::Post.new(uri)
    req['SEC'] = @sec
    req['accept'] = "application/json"
    req['Version'] = Config.global.api_version
    req["Content-Type"] = "application/json"
    req.set_form_data({:assigned_to => 'sems'})
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    get_offense = JSON.parse(res.body)
  end

  def self.get_source_address source_adress_id
    uri = URI("#{@host}/api/siem/source_addresses//#{source_adress_id}")
    req = Net::HTTP::Get.new(uri)
    req['SEC'] = @sec
    req['Version'] = Config.global.api_version
    req['accept'] = "application/json"
    req["Content-Type"] = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
      http.request(req)
    }
    get_source_address = JSON.parse(res.body)["name"]
  end
end


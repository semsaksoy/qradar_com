require 'rubygems'
require 'rubygems/gem_runner'
require 'rubygems/exceptions'
require 'net/http'
require "json"
require "time"
require 'openssl'
require "erb"


##config
@sec = "cc947788***********"
@host="https://127.0.0.1"
@path=File.dirname(__FILE__)


@receiver_hash={
    "Domain name1" => "person1@mail.com,person2@mail.com",
    "Domain name1" => "person1@mail.com",
    "Domain name1" => "person1@mail.com,person2@mail.com",
    "Domain name1" => "person1@mail.com,person2@mail.com",
    "Domain name1" => "person1@mail.com,person2@mail.com",
    "Domain name1" => "person1@mail.com,person2@mail.com",
    "Domain name1" => "person1@mail.com,person2@mail.com",
    "Default Domain" => "person1@mail.com,person2@mail.com"
}


@url_host="https://172.16.1.75" #offense following link in mail

@sender="Qradar <qradar@sample.qr>"
@subject="New Offense Created"
@risk_magnitude=5

##config


@options = {}

@o_t_hash={0 => "Source IP",
           1 => "Destination IP",
           2 => "Event Name",
           3 => "Username",
           4 => "Source MAC Address",
           5 => "Destination MAC Address",
           6 => "Log Source",
           7 => "Hostname",
           8 => "Source Port",
           9 => "Destination Port",
           10 => "Source IPv6",
           11 => "Destination IPv6",
           12 => "Source ASN",
           13 => "Destination ASN",
           14 => "Rule",
           15 => "App Id",
           18 => "Scheduled Search"


}


def gem_install(lib)
  begin

    Gem::GemRunner.new.run ['install', "#{lib}.gem", "--local"] unless Gem::Specification.map { |g| g.name }.include?(lib)
  rescue Gem::SystemExitException => e
    p e
  end
end

# gem_install "terminal-table"
# require "terminal-table"

def turkce(ing)
  begin
    url= "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=tr&dt=t&q=#{ing}"
    uri = URI(url)
    JSON.parse(Net::HTTP.get(uri)).flatten.first
  rescue
    turkce="Translation Error"
  end
end

def get_last
  File.read("#{@path}/last.db").strip
end


def get_offense(offense_id)

  uri = URI("#{@host}/api/siem/offenses/#{offense_id}")
  req = Net::HTTP::Get.new(uri)
  req['SEC'] = @sec
  req['accept'] = "application/json"
  req['Version']= "7.2"
  req["Content-Type"]= "application/json"

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
    http.request(req)
  }
  get_offense= JSON.parse(res.body)
end

def get_last_offenses(offense_id)
  uri = URI("#{@host}/api/siem/offenses?filter=id%20%3E%20#{offense_id}")
  req = Net::HTTP::Get.new(uri)
  req['SEC'] = @sec
  req['accept'] = "application/json"
  req['Version']= "7.2"
  req["Content-Type"]= "application/json"

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
    http.request(req)
  }
  get_last_offenses= JSON.parse(res.body)
  get_last_offenses=get_last_offenses.map { |o| o["id"] }.sort

end

def get_offense_type(offense_type_id)
  unless @o_t_hash[offense_type_id].nil?
    return @o_t_hash[offense_type_id]
  end

  uri = URI("#{@host}/api/siem/offense_types/#{offense_type_id}")
  req = Net::HTTP::Get.new(uri)
  req['SEC'] = @sec
  req['Version']= "7.2"
  req['accept'] = "application/json"
  req["Content-Type"]= "application/json"

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
    http.request(req)
  }
  get_offense_type= JSON.parse(res.body)["name"]

end

def get_source_address source_adress_id


  uri = URI("#{@host}/api/siem/source_addresses//#{source_adress_id}")
  req = Net::HTTP::Get.new(uri)
  req['SEC'] = @sec
  req['Version']= "7.2"
  req['accept'] = "application/json"
  req["Content-Type"]= "application/json"

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
    http.request(req)
  }
  get_source_address= JSON.parse(res.body)["name"]

end

def get_domain domain_id
  return "Default Domain" if domain_id==0 or domain_id.nil?
  uri = URI("#{@host}/api/config/domain_management/domains/#{domain_id}")
  req = Net::HTTP::Get.new(uri)
  req['SEC'] = @sec
  req['Version']= "7.2"
  req['accept'] = "application/json"
  req["Content-Type"]= "application/json"

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
    http.request(req)
  }
  get_source_address= JSON.parse(res.body)["name"]
end

def set_offense(offense_id)

  uri = URI("#{@host}/api/siem/offenses/#{offense_id}")
  req = Net::HTTP::Post.new(uri)
  req['SEC'] = @sec
  req['accept'] = "application/json"
  req['Version']= "7.2"
  req["Content-Type"]= "application/json"

  req.set_form_data({:assigned_to => 'sems'})


  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http|
    http.request(req)
  }
  get_offense= JSON.parse(res.body)
end



class OffenseController

  def self.action(offense_id)
    Thread.new do
      sleep (Config.global.delay_min * 60)
      o = Offense.new offense_id
      o.get_events
      o.get_first_event
      o.get_event_description
      o.render
    end

    #print "bitti"
  end

  def self.turkce(ing)
    begin
      url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=tr&dt=t&q=#{ing}"
      uri = URI(url)
      JSON.parse(Net::HTTP.get(uri)).flatten.first
    rescue
      turkce = "Translation Error"
    end
  end

  def self.get_last
    File.read("#{Config.global.root}/last.db").strip
  end
end


require_relative "helper"


def action(offense_id)
  of=get_offense offense_id

  @id=of["id"]
  @description_en=of["description"]
  @description_tr=turkce(of["description"])
  @magnitude=of["magnitude"]
  @severity=of["severity"]
  @relevance=of["relevance"]
  @credibility=of["credibility"]
  @status=of["status"]
  @domain_id= get_domain of["domain_id"]
  @offense_source=of["offense_source"]
  @offense_type=get_offense_type of["offense_type"]
  @flow_count=of["flow_count"]
  @event_count=of["event_count"]
  @categories=of["categories"]
  @link="#{@url_host}/console/do/sem/offensesummary?appName=Sem&pageId=OffenseSummary&summaryId=#{@id}"

  @start_time=Time.strptime(of["start_time"].to_s, "%Q").localtime.strftime("%d.%m.%Y %H:%M:%S")
  @last_updated_time=Time.strptime(of["last_updated_time"].to_s, "%Q").localtime.strftime("%d.%m.%Y %H:%M:%S")


  renderer = ERB.new(File.read("#{@path}/view/offense.erb"))
  cikti= renderer.result.gsub("\'", "\"")

  File.write("test.html", cikti)
  risk=""
  if @magnitude.to_i>@risk_magnitude
    risk="!! Risky "
  end

  komut="(echo 'To: #{@receiver_hash[@domain_id]}'
echo 'From: #{@sender}'
echo 'Subject: #{risk}#{@subject}'
echo 'Content-Type: text/html'
echo;
echo '#{cikti}' ) | sendmail -t"

  begin
    `#{komut}`
  rescue
    p "mail gitmedi"
  end
end

last=get_last_offenses(get_last)


last.each do |oid|
  action oid
end

unless last.empty?
  File.write("#{@path}/last.db", last.last)
end


#p get_offense 1
#p set_offense(3)

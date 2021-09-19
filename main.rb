require_relative "env"

while true

  begin
    get_last = OffenseController.get_last
    last = Offense.get_last_offenses(get_last)


    last.each do |oid|
      OffenseController.action oid
    end

    unless last.empty?
      File.write("#{Config.global.root}/last.db", last.last)
    end

  rescue => error
    print error.message
  end

  sleep Config.global.control_frequency * 60
end


#p get_offense 1
#p set_offense(3)

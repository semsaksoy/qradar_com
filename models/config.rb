class Config
  def root
    File.dirname(__dir__)
  end

  FILE_PATH = "#{ File.dirname(__dir__)}/config.json"
  attr_reader(*JSON.parse(File.read("#{FILE_PATH}")).keys)

  def initialize
    self.load
  end

  @event_dir_cache = nil

  def load
    j = JSON.parse(File.read(FILE_PATH))
    j.keys.each do |k|
      instance_variable_set("@#{k}", j[k])
    end
  end

  def self.global
    @@global
  end

  def self.otm
    #offense type map
    {0 => "Source IP",
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
  end

  @@global = self.new
end
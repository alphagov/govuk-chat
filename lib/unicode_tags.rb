module UnicodeTags
  RANGE_START = 0xE0001
  RANGE_END = 0xE007E
  DECODE_SUBTRACT = 0xE0000
  RANGE_STRING = "#{RANGE_START.chr(Encoding::UTF_8)}-#{RANGE_END.chr(Encoding::UTF_8)}".freeze
  MATCH_REGEX = Regexp.new("[#{RANGE_STRING}]")
  SCAN_REGEX = Regexp.new("[#{RANGE_STRING}]+|[^#{RANGE_STRING}]+")
end

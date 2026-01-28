module PiiValidator
  # Uses URI::MailTo::EMAIL_REGEXP but removes the start and end of string matchers
  EMAIL_REGEX = /\b[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\b/

  CREDIT_CARD_REGEX = /
                      \b # word boundary
                      \d{13,16} # 13 to 16 digits
                      |\d{4}\s\d{4}\s\d{4}\s\d{4} # 4 groups of 4 digits separated by spaces (Normal CC number)
                      |\d{4}\s\d{6}\s\d{5} #4 digits, 6 digits, 5 digits separated by spaces (AMEX)
                      \b # word boundary
                      /x

  PHONE_NUMBER_REGEX = /
                      \b # word boundary
                      (?:\+?(\d{1,3}))? # country code, optional
                      \s? # space, optional
                      [-.(]? # dash, dot or open brace, optional
                      (\d{3,5})? # area code, optional, can be up to 5 digits in UK
                      [-.)]? # dash, dot or close brace, optional
                      \s? # space, optional
                      (\d{3}) # first segment of number, required
                      [-.\s]?  # space or other punctuation
                      (\d{3,4}) # second segment of number, 3 or 4 digits to allow UK 6 digit numbers, required
                      \b # word boundary
                      /x

  NATIONAL_INSURANCE_NUMBER_REGEX = /
                                    \b # word boundary
                                    [A-Za-z]{2} # 2 letters
                                    \s? # space, optional
                                    ([0-9 ]+){6,8} # 6 to 8 digits or spaces
                                    \s? # space, optional
                                    [A-Za-z] # 1 letter
                                    \b # word boundary
                                    /x

  PII_REGEXS = [
    EMAIL_REGEX,
    CREDIT_CARD_REGEX,
    PHONE_NUMBER_REGEX,
    NATIONAL_INSURANCE_NUMBER_REGEX,
  ].freeze

  def self.invalid?(input)
    PII_REGEXS.any? { |regex| input.match?(regex) }
  end
end

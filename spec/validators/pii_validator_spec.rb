RSpec.describe PiiValidator do
  describe "self.invalid?" do
    context "when the input does not contain any personal information" do
      it "returns false" do
        user_question = "How much VAT do i have to pay?"
        expect(described_class.invalid?(user_question)).to be false
      end
    end

    context "when the input contains an email address" do
      it "returns true" do
        email_addresses = %w[
          test@gmail.com
          test@localhost
          test.user@yahoo.co.uk
        ]

        email_addresses.each do |email_address|
          user_question = "My email address is #{email_address}"
          expect(described_class.invalid?(user_question)).to be true
        end
      end
    end

    context "when the input contains a credit card number" do
      it "returns true for 13-16 digit numbers" do
        credit_card_numbers = %w[
          1234567890123
          12345678901234
          123456789012345
          1234567890123456
        ]

        credit_card_numbers.each do |credit_card_number|
          user_question = "My credit card number is #{credit_card_number}"
          expect(described_class.invalid?(user_question)).to be true
        end
      end

      it "returns true when the it contains a normal credit card number" do
        user_question = "My credit card number is 1234 5678 9012 3456"
        expect(described_class.invalid?(user_question)).to be true
      end

      it "returns true when the it contains an AMEX credit card number" do
        user_question = "My credit card number is 1234 567890 12345"
        expect(described_class.invalid?(user_question)).to be true
      end
    end

    context "when the input contains a uk or international phone number" do
      it "returns true" do
        phone_numbers = [
          "07555666777",
          "(01234)555666",
          "01234 555666",
          "(01234) 555666",
          "+441234567890",
          "+(44)1234567890",
          "+44 1234567890",
          "+(44) 1234567890",
          "+44 1234 567890",
          "+(44) 1234 567890",
          "+44 1234 567 890",
          "+(44) 1234 567 890",
          "+11234567",
          "+112345678",
          "+1123456789",
          "+11234567890",
          "+121234567890",
          "+1231234567890",
          "+(123)1234567890",
          "+1 1234567",
          "+1 12345678",
          "+1 123456789",
          "+1 1234567890",
          "+12 1234567890",
          "+123 1234567890",
          "+(123) 1234567890",
          "+1 123 4567890",
          "+(123) 123 4567",
          "+1-123-4567890",
          "+(123)-123-4567",
          "+1.123.4567890",
          "+(123).123.4567",
        ]

        phone_numbers.each do |phone_number|
          user_question = "My phone number is #{phone_number}"
          expect(described_class.invalid?(user_question)).to be true
        end
      end
    end

    context "when the input contains a national insurance number" do
      it "returns true" do
        ni_numbers = ["AB 12 34 56 A", "AB123456A", "AB 123 456 A", "AB 123 456A", "AB123456 A", "AB 123456A"]

        ni_numbers.each do |ni_number|
          user_question = "My ni number is #{ni_number}"
          expect(described_class.invalid?(user_question)).to be true
        end
      end
    end
  end
end

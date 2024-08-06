class Admin::Form::Settings::BaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  AUTHOR_COMMENT_LENGTH_ERROR_MESSAGE = "Author comment must be %{count} characters or less".freeze

  attribute :author_comment, :string
  attribute :user

  validates :author_comment, length: { maximum: 255, message: AUTHOR_COMMENT_LENGTH_ERROR_MESSAGE }

private

  def settings
    @settings ||= Settings.instance
  end
end

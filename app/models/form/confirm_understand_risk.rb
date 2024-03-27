class Form::ConfirmUnderstandRisk
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :confirmation

  validates :confirmation, presence: { message: "Check the checkbox to show you understand the guidance" }
end

class Admin::Form::Settings::WaitingListPromotionsPerRunForm < Admin::Form::Settings::BaseForm
  MAX_PROMOTIONS = 200
  attribute :promotions_per_run, :integer

  validates :promotions_per_run, presence: { message: "Enter the number of promotions per run" }
  validates :promotions_per_run,
            numericality: { in: 0..MAX_PROMOTIONS, message: "Enter an integer between 0 and #{MAX_PROMOTIONS} for promotions per run" },
            if: -> { promotions_per_run.present? }

  def submit
    validate!
    return if promotions_per_run == settings.waiting_list_promotions_per_run

    action = "Updated waiting list promotions per run to #{promotions_per_run}"
    settings.locked_audited_update(user, action, author_comment) do
      settings.waiting_list_promotions_per_run = promotions_per_run
    end
  end
end

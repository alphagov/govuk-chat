module Admin::Concerns::QuestionFilterConcern
  extend ActiveSupport::Concern

private

  def questions_filter(conversation = nil)
    filter_params = params.permit(
      :search,
      :status,
      { start_date_params: %i[day month year], end_date_params: %i[day month year] },
      :page,
    )

    Admin::Form::QuestionsFilter.new(filter_params.merge(conversation:))
  end
end

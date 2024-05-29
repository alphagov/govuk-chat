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

    Admin::Form::QuestionsFilter.new(
      search: filter_params[:search],
      status: filter_params[:status],
      start_date_params: filter_params[:start_date_params] || {},
      end_date_params: filter_params[:end_date_params] || {},
      page: filter_params[:page],
      conversation:,
    )
  end
end

module Admin::Concerns::QuestionFilterConcern
  extend ActiveSupport::Concern

private

  def questions_filter(conversation = nil)
    filter_params = params.permit(:status, :page)
    Admin::Form::QuestionsFilter.new(status: filter_params[:status], page: filter_params[:page], conversation:)
  end
end

class Admin::QuestionsController < Admin::BaseController
  def index
    @filter = questions_filter
    render :index, status: :unprocessable_entity if @filter.errors.present?
  end

  def show
    @question = Question.includes(conversation: %i[user], answer: %i[feedback sources]).find(params[:id])
    @answer = @question.answer
    @question_number = Question.where(conversation: @question.conversation)
                               .where("created_at <= ? ", @question.created_at)
                               .count
    @total_questions = Question.where(conversation: @question.conversation).count
  end

private

  def questions_filter(conversation = nil)
    filter_params = params.permit(
      :search,
      :status,
      { start_date_params: %i[day month year], end_date_params: %i[day month year] },
      :answer_feedback_useful,
      :question_routing_label,
      :page,
      :sort,
      :user_id,
    )

    Admin::Filters::QuestionsFilter.new(filter_params.merge(conversation:))
  end
end

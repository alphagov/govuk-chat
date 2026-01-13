class Admin::QuestionsController < Admin::BaseController
  def index
    @filter = Admin::Filters::QuestionsFilter.new(filter_params)
    render :index, status: :unprocessable_content if @filter.errors.present?
  end

  def show
    question_scope = Question.includes(
      conversation: :signon_user,
      answer: [{ sources: :chunk }, :feedback, :topics, :answer_relevancy_runs, :coherence_runs, :faithfulness_runs],
    )

    @question = question_scope.find(params[:id])
    @answer = @question.answer
    @question_number = Question.where(conversation: @question.conversation)
                               .where("created_at <= ? ", @question.created_at)
                               .count
    @total_questions = Question.where(conversation: @question.conversation).count
  end

private

  def filter_params
    params.permit(
      :search,
      :status,
      :source,
      { start_date_params: %i[day month year], end_date_params: %i[day month year] },
      :answer_feedback_useful,
      :question_routing_label,
      :page,
      :sort,
      :signon_user_id,
      :conversation_id,
      :end_user_id,
      :primary_topic,
      :secondary_topic,
      :completeness,
    )
  end
end

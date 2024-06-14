class Admin::QuestionsController < Admin::BaseController
  include Admin::Concerns::QuestionFilterConcern

  def index
    @filter = questions_filter
    render :index, status: :unprocessable_entity if @filter.errors.present?
  end

  def show
    @question = Question.includes(:conversation, answer: %i[feedback sources]).find(params[:id])
    @answer = @question.answer
    @question_number = Question.where(conversation: @question.conversation)
                               .where("created_at <= ? ", @question.created_at)
                               .count
    @total_questions = Question.where(conversation: @question.conversation).count
  end
end

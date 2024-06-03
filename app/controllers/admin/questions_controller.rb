class Admin::QuestionsController < Admin::BaseController
  include Admin::Concerns::QuestionFilterConcern

  def index
    @filter = questions_filter
  end

  def show
    @question = Question.includes(answer: :sources).find(params[:id])
    @answer = @question.answer
    @question_number = Question.where(conversation: @question.conversation)
                               .where("created_at <= ? ", @question.created_at)
                               .count
    @total_questions = Question.where(conversation: @question.conversation).count
  end
end

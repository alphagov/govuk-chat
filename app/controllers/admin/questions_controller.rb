class Admin::QuestionsController < Admin::BaseController
  include Admin::Concerns::QuestionFilterConcern

  def index
    @filter = questions_filter
  end

  def show
    @question = Question.includes(answer: :sources).find(params[:id])
    @answer = @question.answer
  end
end

class Admin::QuestionsController < Admin::BaseController
  def index
    @questions = Question.includes(:answer)
                         .order(created_at: :desc)
                         .page(params[:page])
  end

  def show
    @question = Question.includes(answer: :sources).find(params[:id])
    @answer = @question.answer
  end
end

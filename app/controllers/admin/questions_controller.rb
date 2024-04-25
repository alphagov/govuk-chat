class Admin::QuestionsController < Admin::BaseController
  def index
    @questions = Question.includes(:answer).order(created_at: :desc)
  end
end

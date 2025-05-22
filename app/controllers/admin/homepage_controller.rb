class Admin::HomepageController < Admin::BaseController
  def index
    @questions_total = Question.count
  end
end

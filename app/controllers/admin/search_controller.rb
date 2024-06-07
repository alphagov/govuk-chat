class Admin::SearchController < Admin::BaseController
  def index
    @search_text = params[:search_text]
    @result_set = perform_search
  end

private

  def perform_search
    return Search::ResultsForQuestion::ResultSet.empty if @search_text.blank?

    Search::ResultsForQuestion.call(@search_text)
  end
end

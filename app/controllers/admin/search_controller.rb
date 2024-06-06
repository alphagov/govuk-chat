class Admin::SearchController < Admin::BaseController
  def index
    @search_text = params[:search_text]
    @search_results = search_results
  end

private

  def search_results
    return [] if @search_text.blank?

    Search::ResultsForQuestion.call(@search_text).results
  end
end

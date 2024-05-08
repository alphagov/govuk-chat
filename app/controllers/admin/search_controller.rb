class Admin::SearchController < Admin::BaseController
  def index
    @search_text = params[:search_text]
    @search_results = search_results
  end

private

  def search_results
    return [[]] if @search_text.blank?

    Search::ResultsForQuestion.call(@search_text).map(&method(:map_result))
  end

  def map_result(result)
    [
      { text: result.title },
      { text: result.base_path },
      { text: format_content(result.plain_content) },
      { text: result.score, format: "numeric" },
    ]
  end

  def format_content(content)
    return content if content.length < 50

    "#{content.truncate_words(10)}#{content.last(50)}"
  end
end

class Admin::ChunksController < Admin::BaseController
  before_action :set_back_link
  before_action :set_score_calculation

  def show
    repository = Search::ChunkedContentRepository.new
    @chunk = repository.chunk(id)
    @chunks_for_base_path = repository.count(term: { base_path: @chunk.base_path })
  end

private

  def set_back_link
    @back_link = params[:back_link] if back_link_allowed?
  end

  def set_score_calculation
    @score_calculation = params[:score_calculation]
  end

  def back_link_allowed?
    params[:back_link] && params[:back_link].start_with?(admin_search_path)
  end

  def id
    params[:id]
  end
end

class Admin::ChunksController < Admin::BaseController
  before_action :set_back_link

  def show
    @chunk = Search::ChunkedContentRepository.new.chunk(id)
  end

private

  def set_back_link
    @back_link = params[:back_link] if back_link_allowed?
  end

  def back_link_allowed?
    params[:back_link] && params[:back_link].start_with?(admin_search_path)
  end

  def id
    params[:id]
  end
end

class Admin::ChunksController < Admin::BaseController
  def show
    @chunk = Search::ChunkedContentRepository.new.chunk(params[:id])
  end
end

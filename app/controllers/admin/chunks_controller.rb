class Admin::ChunksController < Admin::BaseController
  def show
    @chunk = Search::ChunkedContentRepository.new.chunk(params[:id])
  rescue Search::ChunkedContentRepository::NotFound
    redirect_to "/404"
  end
end

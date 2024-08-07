module Admin::PaginationHelper
  def previous_and_next_page_hash(paginator, previous_page_url:, next_page_url:)
    pages = {}

    if paginator.prev_page
      pages[:previous_page] = {
        url: previous_page_url,
        label: "#{paginator.current_page - 1} of #{paginator.total_pages}",
        title: "Previous page",
      }
    end

    if paginator.next_page
      pages[:next_page] = {
        url: next_page_url,
        label: "#{paginator.current_page + 1} of #{paginator.total_pages}",
        title: "Next page",
      }
    end

    pages
  end
end

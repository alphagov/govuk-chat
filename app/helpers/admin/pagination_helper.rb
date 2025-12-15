module Admin::PaginationHelper
  def pagination_component_args(paginator, previous_page_href:, next_page_href:)
    pages = {}

    if paginator.prev_page
      pages[:previous_page] = {
        href: previous_page_href,
        label: "#{paginator.current_page - 1} of #{paginator.total_pages}",
        title: "Previous page",
      }
    end

    if paginator.next_page
      pages[:next_page] = {
        href: next_page_href,
        label: "#{paginator.current_page + 1} of #{paginator.total_pages}",
        title: "Next page",
      }
    end

    pages
  end
end

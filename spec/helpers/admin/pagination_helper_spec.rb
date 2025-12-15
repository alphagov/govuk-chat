RSpec.describe Admin::PaginationHelper do
  describe "#pagination_component_args" do
    context "when the paginator has a next page and no previous page" do
      it "returns a hash with the next page href, label, and title" do
        paginator = Kaminari.paginate_array(Array.new(2)).page(1).per(1)

        expect(pagination_component_args(
                 paginator,
                 previous_page_href: nil,
                 next_page_href: "/test?page=2",
               ))
          .to eq(
            {
              next_page: {
                href: "/test?page=2",
                label: "2 of 2",
                title: "Next page",
              },
            },
          )
      end
    end

    context "when the paginator has a previous page and no next page" do
      it "returns a hash with the previous page url, label, and title" do
        paginator = Kaminari.paginate_array(Array.new(2)).page(2).per(1)

        expect(pagination_component_args(
                 paginator,
                 previous_page_href: "/test?page=1",
                 next_page_href: nil,
               ))
          .to eq(
            {
              previous_page: {
                href: "/test?page=1",
                label: "1 of 2",
                title: "Previous page",
              },
            },
          )
      end
    end

    context "when the paginator has a previous page and next page" do
      it "returns a hash with the previous and next page attributes" do
        paginator = Kaminari.paginate_array(Array.new(3)).page(2).per(1)

        expect(pagination_component_args(
                 paginator,
                 previous_page_href: "/test?page=1",
                 next_page_href: "/test?page=3",
               ))
          .to eq(
            {
              previous_page: {
                href: "/test?page=1",
                label: "1 of 3",
                title: "Previous page",
              },
              next_page: {
                href: "/test?page=3",
                label: "3 of 3",
                title: "Next page",
              },
            },
          )
      end
    end

    context "when there is no previous or next page" do
      it "returns an empty hash" do
        paginator = Kaminari.paginate_array(Array.new(1)).page(1).per(1)

        expect(pagination_component_args(paginator, previous_page_href: nil, next_page_href: nil))
          .to eq({})
      end
    end
  end
end

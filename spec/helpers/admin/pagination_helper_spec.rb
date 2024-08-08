RSpec.describe Admin::PaginationHelper do
  describe "#previous_and_next_page_hash" do
    context "when the paginator has a next page and no previous page" do
      it "returns a hash with the next page url, label, and title" do
        paginator = Kaminari.paginate_array(Array.new(2)).page(1).per(1)

        expect(previous_and_next_page_hash(
                 paginator,
                 previous_page_url: nil,
                 next_page_url: "/test?page=2",
               ))
          .to eq(
            {
              next_page: {
                url: "/test?page=2",
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

        expect(previous_and_next_page_hash(
                 paginator,
                 previous_page_url: "/test?page=1",
                 next_page_url: nil,
               ))
          .to eq(
            {
              previous_page: {
                url: "/test?page=1",
                label: "1 of 2",
                title: "Previous page",
              },
            },
          )
      end
    end

    context "when the paginator has a previous page and next page" do
      it "returns a hash with the previous page url, label, and title" do
        paginator = Kaminari.paginate_array(Array.new(3)).page(2).per(1)

        expect(previous_and_next_page_hash(
                 paginator,
                 previous_page_url: "/test?page=1",
                 next_page_url: "/test?page=3",
               ))
          .to eq(
            {
              previous_page: {
                url: "/test?page=1",
                label: "1 of 3",
                title: "Previous page",
              },
              next_page: {
                url: "/test?page=3",
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

        expect(previous_and_next_page_hash(paginator, previous_page_url: nil, next_page_url: nil))
          .to eq({})
      end
    end
  end
end

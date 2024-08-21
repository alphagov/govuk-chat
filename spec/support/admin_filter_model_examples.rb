module AdminFilterModelExamples
  shared_examples "a paginatable filter" do |factory_name|
    describe "#previous_page_params" do
      it "returns any empty hash if there is no previous page to link to" do
        filter = described_class.new
        expect(filter.previous_page_params).to eq({})
      end

      it "constructs the previous pages url based on the path passed in when a previous page is present" do
        create_list(factory_name, 51)
        filter = described_class.new(page: 3)
        expect(filter.previous_page_params).to eq({ page: 2 })
      end

      it "removes the page param from the url correctly when it links to the first page of records" do
        create_list(factory_name, 26)
        filter = described_class.new(page: 2)
        expect(filter.previous_page_params).to eq({})
      end
    end

    describe "#next_page_params" do
      it "returns any empty hash if there is no next page to link to" do
        filter = described_class.new
        expect(filter.next_page_params).to eq({})
      end

      it "constructs the next page based on the path passed in when a next page is present" do
        create_list(factory_name, 26)
        filter = described_class.new(page: 1)
        expect(filter.next_page_params).to eq({ page: 2 })
      end
    end
  end

  shared_examples "a sortable filter" do |sort_field|
    describe "#sort_direction" do
      it "returns nil when sort does not match the field passed in" do
        filter = described_class.new(sort: sort_field)
        other_sort_field = described_class.valid_sort_values.reject { |v| v == sort_field }.sample
        expect(filter.sort_direction(other_sort_field)).to be_nil
      end

      it "returns 'ascending' when sort equals the field passed in" do
        filter = described_class.new(sort: sort_field)
        expect(filter.sort_direction(sort_field)).to eq("ascending")
      end

      it "returns 'descending' when sort prefixed with '-' equals the field passed in" do
        filter = described_class.new(sort: "-#{sort_field}")
        expect(filter.sort_direction(sort_field)).to eq("descending")
      end
    end

    describe "#toggleable_sort_params" do
      it "sets the page param to nil" do
        filter = described_class.new(sort: "-#{sort_field}", page: 2)
        expect(filter.toggleable_sort_params("-#{sort_field}")).to eq(
          { sort: sort_field, page: nil },
        )
      end

      context "when the sort attribute does not match the default_field_sort" do
        it "sets the sort_param to the default_field_sort" do
          filter = described_class.new(sort: sort_field)
          expect(filter.toggleable_sort_params("-#{sort_field}")).to eq(
            { sort: "-#{sort_field}", page: nil },
          )
        end
      end

      context "when the sort attribute matches the default_field_sort" do
        it "sets the sort_param to 'ascending' if the sort attribute is 'descending'" do
          filter = described_class.new(sort: "-#{sort_field}")
          expect(filter.toggleable_sort_params("-#{sort_field}")).to eq(
            { sort: sort_field, page: nil },
          )
        end

        it "sets the sort_param to 'descending' if the sort attribute is 'ascending'" do
          filter = described_class.new(sort: sort_field)
          expect(filter.toggleable_sort_params(sort_field)).to eq(
            { sort: "-#{sort_field}", page: nil },
          )
        end
      end
    end
  end
end

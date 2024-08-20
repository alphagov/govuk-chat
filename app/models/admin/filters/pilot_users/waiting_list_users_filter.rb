class Admin::Filters::PilotUsers::WaitingListUsersFilter < Admin::Filters::BaseFilter
  attribute :email

  def self.default_sort
    "-created_at"
  end

  def self.valid_sort_values
    ["created_at", "-created_at", "email", "-email"]
  end

  def results
    @results ||= begin
      scope = WaitingListUser
      scope = email_scope(scope)
      scope = ordering_scope(scope)
      scope.page(page).per(25)
    end
  end

private

  def pagination_query_params
    filters = {}
    filters[:email] = email if email.present?
    filters[:sort] = sort if sort != self.class.default_sort

    filters
  end
end

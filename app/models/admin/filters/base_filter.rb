class Admin::Filters::BaseFilter
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :sort
  attribute :page, :integer

  def initialize(...)
    super

    self.sort = self.class.default_sort unless self.class.valid_sort_values.include?(sort)
  end

  def previous_page_params
    if results.prev_page == 1 || results.prev_page.nil?
      pagination_query_params
    else
      pagination_query_params.merge(page: results.prev_page)
    end
  end

  def next_page_params
    if results.next_page.present?
      pagination_query_params.merge(page: results.next_page)
    else
      pagination_query_params
    end
  end

  def sort_direction(field)
    return unless sort.delete_prefix("-") == field

    sort.starts_with?("-") ? "descending" : "ascending"
  end

  def toggleable_sort_params(default_field_sort)
    sort_param = if sort == default_field_sort
                   sort.starts_with?("-") ? sort.delete_prefix("-") : "-#{sort}"
                 else
                   default_field_sort
                 end

    pagination_query_params.merge(sort: sort_param, page: nil)
  end

  def email_scope(scope)
    return scope if email.blank?

    scope.where("email ILIKE ?", "%#{email}%")
  end

protected

  def ordering_scope(scope)
    column = sort.delete_prefix("-")
    direction = sort.start_with?("-") ? :desc : :asc
    scope.order("#{column}": direction)
  end
end

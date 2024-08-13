class Admin::Form::EarlyAccessUsersFilter
  include ActiveModel::Model
  include ActiveModel::Attributes

  DEFAULT_SORT = "-last_login_at".freeze
  VALID_SORT_VALUES = ["last_login_at", "-last_login_at", "email", "-email"].freeze

  attribute :email
  attribute :source
  attribute :revoked, :boolean
  attribute :sort
  attribute :page, :integer

  def initialize(...)
    super
    self.sort = DEFAULT_SORT unless VALID_SORT_VALUES.include?(sort)
  end

  def users
    @users ||= begin
      scope = EarlyAccessUser
      scope = email_scope(scope)
      scope = source_scope(scope)
      scope = revoked_scope(scope)
      scope = ordering_scope(scope)
      scope.page(page).per(25)
    end
  end

  def previous_page_params
    if users.prev_page == 1 || users.prev_page.nil?
      pagination_query_params
    else
      pagination_query_params.merge(page: users.prev_page)
    end
  end

  def next_page_params
    if users.next_page.present?
      pagination_query_params.merge(page: users.next_page)
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

private

  def pagination_query_params
    filters = {}
    filters[:email] = email if email.present?
    filters[:source] = source if source.present?
    filters[:sort] = sort if sort != DEFAULT_SORT

    filters
  end

  def email_scope(scope)
    return scope if email.blank?

    scope.where("email ILIKE ?", "%#{email}%")
  end

  def source_scope(scope)
    return scope if source.blank?

    scope.where(source:)
  end

  def revoked_scope(scope)
    return scope if revoked.nil?

    revoked ? scope.where.not(revoked_at: nil) : scope.where(revoked_at: nil)
  end

  def ordering_scope(scope)
    column = sort.delete_prefix("-")
    direction = sort.start_with?("-") ? :desc : :asc

    if column == "last_login_at"
      nulls_direction = direction == :desc ? "LAST" : "FIRST"
      scope.order("last_login_at #{direction} NULLS #{nulls_direction}, created_at #{direction}")
    else
      scope.order("#{column}": direction)
    end
  end
end

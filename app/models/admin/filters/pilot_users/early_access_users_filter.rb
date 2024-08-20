class Admin::Filters::PilotUsers::EarlyAccessUsersFilter < Admin::Filters::BaseFilter
  DEFAULT_SORT = "-last_login_at".freeze
  VALID_SORT_VALUES = ["last_login_at", "-last_login_at", "email", "-email"].freeze

  attribute :email
  attribute :source
  attribute :revoked, :boolean

  def initialize(...)
    super
    self.sort = DEFAULT_SORT unless VALID_SORT_VALUES.include?(sort)
  end

  def results
    @results ||= begin
      scope = EarlyAccessUser
      scope = email_scope(scope)
      scope = source_scope(scope)
      scope = revoked_scope(scope)
      scope = ordering_scope(scope)
      scope.page(page).per(25)
    end
  end

private

  def pagination_query_params
    filters = {}
    filters[:email] = email if email.present?
    filters[:source] = source if source.present?
    filters[:sort] = sort if sort != DEFAULT_SORT

    filters
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

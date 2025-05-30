class Admin::Filters::EarlyAccessUsersFilter < Admin::Filters::BaseFilter
  attribute :email
  attribute :source
  attribute :access
  attribute :previous_sign_up_denied, :boolean

  def self.default_sort
    "-last_login_at"
  end

  def self.valid_sort_values
    ["last_login_at", "-last_login_at", "email", "-email", "questions_count", "-questions_count"]
  end

  def results
    @results ||= begin
      scope = EarlyAccessUser
      scope = email_scope(scope)
      scope = source_scope(scope)
      scope = access_scope(scope)
      scope = previous_sign_up_denied_scope(scope)
      scope = ordering_scope(scope)
      scope.page(page).per(25)
    end
  end

private

  def pagination_query_params
    filters = {}
    filters[:email] = email if email.present?
    filters[:source] = source if source.present?
    filters[:sort] = sort if sort != self.class.default_sort

    filters
  end

  def source_scope(scope)
    return scope if source.blank?

    scope.where(source:)
  end

  def access_scope(scope)
    return scope if access.blank?

    if access == "at_question_limit"
      scope.at_question_limit
    else
      scope.where(revoked_at: nil, shadow_banned_at: nil).within_question_limit
    end
  end

  def previous_sign_up_denied_scope(scope)
    return scope if previous_sign_up_denied.nil?

    scope.where(previous_sign_up_denied:)
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

module Admin::EarlyAccessUsersHelper
  def early_access_user_index_email_field(user)
    user_email = if user.revoked_or_banned?
                   tag.s(user.email)
                 else
                   user.email
                 end

    user_suffix = if user.access_revoked?
                    " (revoked)"
                  elsif user.shadow_banned?
                    " (shadow banned)"
                  else
                    ""
                  end

    safe_join([
      link_to(user_email, admin_early_access_user_path(user), class: "govuk-link"),
      user_suffix,
    ])
  end

  def early_access_user_index_questions_field(user)
    return "0" if user.questions_count.zero?

    link = link_to(user.questions_count, admin_questions_path(user_id: user.id), class: "govuk-link")
    return link if user.unlimited_question_allowance?

    safe_join([link, " / ", user.question_limit])
  end
end

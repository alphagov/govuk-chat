class EarlyAccessUserFeedbackMailer < ApplicationMailer
  def request_feedback(user)
    @user_id = user.id
    @unsubscribe_token = user.unsubscribe_token
    @survey_url = "https://surveys.publishing.service.gov.uk/s/govuk-chat-beta?user=#{@user_id}&source=request_feedback_email"
    view_mail(template_id, to: user.email, subject: "Share your experience of GOV.UK Chat")
  end
end

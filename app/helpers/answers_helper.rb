module AnswersHelper
  def render_answer_message(message, skip_sanitize: false)
    message_to_html = Kramdown::Document.new(message).to_html
    render "govuk_publishing_components/components/govspeak" do
      if skip_sanitize
        message_to_html.html_safe
      else
        sanitize(message_to_html)
      end
    end
  end

  def answer_combined_llm_responses(answer)
    return [] if answer.llm_responses.blank?

    answer.llm_responses.sort + (answer.analysis&.llm_responses || []).sort
  end

  def answer_combined_metrics(answer)
    return {} if answer.metrics.blank?
    return answer.metrics if answer.analysis&.metrics.blank?

    answer.metrics.merge(answer.analysis.metrics)
  end
end

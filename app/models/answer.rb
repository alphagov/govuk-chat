class Answer < ApplicationRecord
  module CannedResponses
    NO_CONTENT_FOUND_RESPONSE = "I’m having difficulty finding an answer on GOV.UK. If you rephrase your question, I’ll search again. Or you can ask about something else.".freeze
    ANSWER_SERVICE_ERROR_RESPONSE = "Something went wrong while trying to answer your question. Please try again.".freeze
    TIMED_OUT_RESPONSE = "Something went wrong and I could not find an answer in time. Please try again.".freeze
    UNSUCCESSFUL_REQUEST_MESSAGE = "Something went wrong while trying to answer your question. Please try again.".freeze
    ANSWER_GUARDRAILS_FAILED_MESSAGE = <<~MESSAGE.freeze
      I generated an answer to your question, but it does not meet the GOV.UK Chat content guidelines. This might be because it contains unclear or misleading information, or offers advice about money or your personal circumstances.

      Please try asking about something else or rephrasing your question.
    MESSAGE
    JAILBREAK_GUARDRAILS_FAILED_MESSAGE = "I cannot answer that. Please try asking something else.".freeze
    QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE = <<~MESSAGE.freeze
      I generated an answer to your question, but it does not meet the GOV.UK Chat content guidelines.

      This could be because it contains misleading or inappropriate information, or offers advice about money or your personal circumstances.

      Please try asking something else.
    MESSAGE
    LLM_CANNOT_ANSWER_MESSAGE = "I’m having difficulty finding an answer on GOV.UK. If you rephrase your question, I’ll search again. Or you can ask about something else.".freeze
    FORBIDDEN_TERMS_MESSAGE = ANSWER_GUARDRAILS_FAILED_MESSAGE

    def self.response_for_question_routing_label(label)
      canned_responses = Rails.configuration.question_routing_labels.dig(label, :canned_responses)
      raise "No canned responses for #{label}" unless canned_responses.respond_to?(:sample)

      canned_responses.sample
    end
  end

  GUARDRAIL_STATUSES = { pass: "pass", fail: "fail", error: "error" }.freeze

  STATUSES_EXCLUDED_FROM_REPHRASING = %w[
    guardrails_answer
    guardrails_forbidden_terms
    guardrails_jailbreak
    guardrails_question_routing
  ].freeze

  scope :aggregate_status, ->(status) { where("SPLIT_PART(status::TEXT, '_', 1) = ?", status) }

  belongs_to :question
  has_many :sources, -> { order(relevancy: :asc) }, class_name: "AnswerSource"
  has_one :feedback, class_name: "AnswerFeedback"

  enum :status,
       {
         answered: "answered",
         clarification: "clarification",
         error_answer_guardrails: "error_answer_guardrails",
         error_answer_service_error: "error_answer_service_error",
         error_jailbreak_guardrails: "error_jailbreak_guardrails",
         error_non_specific: "error_non_specific",
         error_question_routing_guardrails: "error_question_routing_guardrails",
         error_timeout: "error_timeout",
         guardrails_answer: "guardrails_answer",
         guardrails_forbidden_terms: "guardrails_forbidden_terms",
         guardrails_jailbreak: "guardrails_jailbreak",
         guardrails_question_routing: "guardrails_question_routing",
         unanswerable_llm_cannot_answer: "unanswerable_llm_cannot_answer",
         unanswerable_no_govuk_content: "unanswerable_no_govuk_content",
         unanswerable_question_routing: "unanswerable_question_routing",
       },
       prefix: true

  enum :question_routing_label,
       {
         about_mps: "about_mps",
         advice_opinions_predictions: "advice_opinions_predictions",
         character_fun: "character_fun",
         genuine_rag: "genuine_rag",
         gov_transparency: "gov_transparency",
         greetings: "greetings",
         harmful_vulgar_controversy: "harmful_vulgar_controversy",
         multi_questions: "multi_questions",
         negative_acknowledgement: "negative_acknowledgement",
         non_english: "non_english",
         personal_info: "personal_info",
         positive_acknowledgement: "positive_acknowledgement",
         vague_acronym_grammar: "vague_acronym_grammar",
       },
       prefix: true

  enum :answer_guardrails_status, GUARDRAIL_STATUSES, prefix: true
  enum :question_routing_guardrails_status, GUARDRAIL_STATUSES, prefix: true
  enum :jailbreak_guardrails_status, GUARDRAIL_STATUSES, prefix: true

  # guardrail failures are stored as an array so they are more challenging
  # to produce aggregate counts of occurrences
  def self.count_guardrails_failures(attribute)
    unless attribute.in?(%i[answer_guardrails_failures question_routing_guardrails_failures])
      raise ArgumentError, "Unexpected attribute: #{attribute}"
    end

    all_query_groups = current_scope&.group_values || []
    guardrail_group_position = all_query_groups.index { |group| group.to_sym == attribute.to_sym }
    raise "must have grouped by #{attribute}" unless guardrail_group_position

    count_result = current_scope.count

    count_result.each_with_object({}) do |(group, count), memo|
      if all_query_groups.length == 1
        # if we have only a single "group" in the query then we know the group
        # value will only comprise of triggered guardrails
        triggered_guardrails = group
        triggered_guardrails.each do |guardrail|
          memo[guardrail] ||= 0
          memo[guardrail] += count
        end
      else
        # if there are multiple "groups" in the query then some could come
        # before the answer_guardrails_failures with others after
        before_groupings = group.take(guardrail_group_position)
        triggered_guardrails = group[guardrail_group_position]
        after_groupings = group.drop(guardrail_group_position + 1)

        triggered_guardrails.each do |guardrail|
          new_group = before_groupings + [guardrail] + after_groupings
          memo[new_group] ||= 0
          memo[new_group] += count
        end
      end
    end
  end

  def build_sources_from_search_results(search_results)
    self.sources = search_results.map.with_index do |result, relevancy|
      sources.build(
        base_path: result.base_path,
        exact_path: result.exact_path,
        title: result.title,
        relevancy:,
        content_chunk_id: result._id,
        content_chunk_digest: result.digest,
        heading: result.heading_hierarchy.last,
      )
    end
  end

  def serialize_for_export
    as_json.merge("sources" => sources.map(&:serialize_for_export))
  end

  def assign_metrics(namespace, values)
    self.metrics ||= {}
    self.metrics[namespace] = values
  end

  def assign_llm_response(namespace, hash)
    self.llm_responses ||= {}
    self.llm_responses[namespace] = hash
  end

  def use_in_rephrasing?
    STATUSES_EXCLUDED_FROM_REPHRASING.exclude?(status)
  end

  def set_sources_as_unused
    sources.each { |source| source.used = false }
  end

  def group_used_answer_sources_by_base_path
    sources_by_base_path = sources.used.group_by(&:base_path)

    sources_by_base_path.map do |base_path, group|
      result = group.first
      path = group.count == 1 ? result.exact_path : base_path

      title = result.title
      title += ": #{result.heading}" if group.count == 1 && result.heading.present?

      {
        href: "#{Plek.website_root}#{path}",
        title:,
      }
    end
  end
end

class Answer < ApplicationRecord
  include LlmCallsRecordable

  module CannedResponses
    NO_CONTENT_FOUND_RESPONSE = "I’m having difficulty finding an answer on GOV.UK. If you rephrase your question, I’ll search again. Or you can ask about something else.".freeze
    ANSWER_SERVICE_ERROR_RESPONSE = "Sorry, I experienced a technical error while trying to answer your question. Please try again.".freeze
    TIMED_OUT_RESPONSE = "Sorry, I experienced a technical error and I could not find an answer in time. Please try again.".freeze
    UNSUCCESSFUL_REQUEST_MESSAGE = "Sorry, I experienced a technical error while trying to answer your question. Please try again.".freeze
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

  STATUSES_EXCLUDED_FROM_TOPIC_ANALYSIS = %w[
    error_answer_guardrails
    error_answer_service_error
    error_jailbreak_guardrails
    error_non_specific
    error_question_routing_guardrails
    error_timeout
    guardrails_jailbreak
  ].freeze

  scope :aggregate_status, ->(status) { where("SPLIT_PART(status::TEXT, '_', 1) = ?", status) }

  after_commit :send_answer_count_to_prometheus, on: :create

  belongs_to :question
  has_many :sources, -> { order(relevancy: :asc) }, class_name: "AnswerSource"
  has_one :feedback, class_name: "AnswerFeedback"
  has_one :topics, class_name: "AnswerAnalysis::Topics"
  has_many :answer_relevancy_runs,
           -> { order(:created_at) },
           class_name: "AnswerAnalysis::AnswerRelevancyRun"
  has_many :coherence_runs,
           -> { order(:created_at) },
           class_name: "AnswerAnalysis::CoherenceRun"
  has_many :faithfulness_runs,
           -> { order(:created_at) },
           class_name: "AnswerAnalysis::FaithfulnessRun"
  has_many :context_relevancy_runs,
           -> { order(:created_at) },
           class_name: "AnswerAnalysis::ContextRelevancyRun"
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
         about_chat: "about_chat",
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
         requires_account_data: "requires_account_data",
         positive_acknowledgement: "positive_acknowledgement",
         vague_acronym_grammar: "vague_acronym_grammar",
         unclear_intent: "unclear_intent",
       },
       prefix: true

  enum :answer_guardrails_status, GUARDRAIL_STATUSES, prefix: true
  enum :question_routing_guardrails_status, GUARDRAIL_STATUSES, prefix: true
  enum :jailbreak_guardrails_status, GUARDRAIL_STATUSES, prefix: true

  enum :completeness,
       {
         complete: "complete",
         partial: "partial",
         no_information: "no_information",
       },
       prefix: true

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
      chunk = AnswerSourceChunk.find_or_create_from_search_result(result)

      sources.build(
        relevancy:,
        chunk:,
        search_score: result.score,
        weighted_score: result.weighted_score,
      )
    end
  end

  def serialize_for_export
    as_json(except: :llm_responses).merge(
      "sources" => sources.map(&:serialize_for_export),
      "llm_responses" => llm_responses.to_json,
    )
  end
  alias_method :serialize_for_evaluation, :serialize_for_export

  def use_in_rephrasing?
    STATUSES_EXCLUDED_FROM_REPHRASING.exclude?(status)
  end

  def eligible_for_topic_analysis?
    STATUSES_EXCLUDED_FROM_TOPIC_ANALYSIS.exclude?(status)
  end

  def set_sources_as_unused
    sources.each { |source| source.used = false }
  end

  def group_used_answer_sources_by_path
    sources
      .used
      .group_by { |source| source.chunk.exact_path.split("#").first }
      .map do |path_minus_fragment, group|
        result = group.first
        title = result.title

        if group.count == 1
          title += ": #{result.heading}" if result.heading.present?

          next {
            href: "#{Plek.website_root}#{result.exact_path}",
            title:,
          }
        end

        # We've chosen to use the first heading in the heading hierarchy instead of the
        # most recent shared heading for each group with multiple sources. While we
        # could obtain the shared heading, we would be unable to deeplink to it as we
        # don't store the uri for each heading in our OpenSearch index.
        # Adding the uri for each heading in the hierarchy would require us to update the index
        # and reindex all of our OpenSearch documents. We will add this functionality to Chat V2
        # if we continue to chunk content by headings.
        title += ": #{result.heading_hierarchy.first}" if result.heading_hierarchy.present?
        {
          href: "#{Plek.website_root}#{path_minus_fragment}",
          title:,
        }
    end
  end

  def has_analysis?
    topics.present? ||
      answer_relevancy_runs.present? ||
      faithfulness_runs.present? ||
      coherence_runs.present? ||
      context_relevancy_runs.present?
  end

  def question_used
    rephrased_question || question.message
  end

  def send_answer_count_to_prometheus
    PrometheusMetrics.increment_counter("answer_count", status:)
  end
end

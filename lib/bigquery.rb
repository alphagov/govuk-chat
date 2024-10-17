module Bigquery
  TOP_LEVEL_MODELS_TO_EXPORT = [Question, AnswerFeedback].freeze
  MODELS_WITH_AGGREGATE_STATS_TO_EXPORT = [EarlyAccessUser, WaitingListUser].freeze
end

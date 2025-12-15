class RenameAnswerAnalysesToAnswerTopics < ActiveRecord::Migration[8.0]
  class AnswerTopics < ApplicationRecord; end

  def up
    rename_table :answer_analyses, :answer_topics

    add_column :answer_topics, :llm_response, :jsonb

    AnswerTopics.find_each do |topic|
      topic.update(llm_response: topic.llm_responses["topic_tagger"])
    end

    remove_column :answer_topics, :llm_responses
  end

  def down
    rename_table :answer_topics, :answer_analyses

    add_column :answer_analyses, :llm_responses, :jsonb

    AnswerTopics.find_each do |topics|
      topics.update(llm_responses: { "topic_tagger" => topics.llm_response })
    end

    remove_column :answer_analyses, :llm_response
  end
end

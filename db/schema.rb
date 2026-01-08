# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_08_130827) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "answer_completeness", ["complete", "partial", "no_information"]
  create_enum "answer_status", ["answered", "clarification", "error_answer_guardrails", "error_answer_service_error", "error_jailbreak_guardrails", "error_non_specific", "error_question_routing_guardrails", "error_timeout", "guardrails_answer", "guardrails_forbidden_terms", "guardrails_jailbreak", "guardrails_question_routing", "unanswerable_llm_cannot_answer", "unanswerable_no_govuk_content", "unanswerable_question_routing"]
  create_enum "conversation_source", ["web", "api"]
  create_enum "guardrails_status", ["pass", "fail", "error"]
  create_enum "question_routing_label", ["about_mps", "advice_opinions_predictions", "character_fun", "genuine_rag", "gov_transparency", "greetings", "harmful_vulgar_controversy", "multi_questions", "negative_acknowledgement", "non_english", "personal_info", "positive_acknowledgement", "vague_acronym_grammar", "unclear_intent", "requires_account_data", "about_chat"]

  create_table "answer_analysis_answer_relevancy_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "score", null: false
    t.string "reason", null: false
    t.jsonb "llm_responses"
    t.jsonb "metrics"
    t.uuid "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_answer_analysis_answer_relevancy_runs_on_answer_id"
  end

  create_table "answer_analysis_topics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "primary_topic"
    t.string "secondary_topic"
    t.jsonb "metrics"
    t.jsonb "llm_responses"
    t.uuid "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_answer_analysis_topics_on_answer_id", unique: true
  end

  create_table "answer_feedback", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "answer_id", null: false
    t.boolean "useful", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_answer_feedback_on_answer_id", unique: true
    t.index ["created_at"], name: "index_answer_feedback_on_created_at"
  end

  create_table "answer_source_chunks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.string "locale", null: false
    t.integer "chunk_index", null: false
    t.string "digest", null: false
    t.string "title", null: false
    t.string "description"
    t.string "heading_hierarchy", default: [], null: false, array: true
    t.string "base_path", null: false
    t.string "exact_path", null: false
    t.string "document_type", null: false
    t.string "parent_document_type"
    t.string "html_content", null: false
    t.string "plain_content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id", "locale", "chunk_index", "digest"], name: "idx_on_content_id_locale_chunk_index_digest_e75f64674c", unique: true
  end

  create_table "answer_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "relevancy", null: false
    t.boolean "used", default: true
    t.uuid "answer_source_chunk_id", null: false
    t.float "search_score"
    t.float "weighted_score"
    t.index ["answer_id", "relevancy"], name: "index_answer_sources_on_answer_id_and_relevancy", unique: true
    t.index ["answer_id"], name: "index_answer_sources_on_answer_id"
    t.index ["answer_source_chunk_id"], name: "index_answer_sources_on_answer_source_chunk_id"
    t.index ["created_at"], name: "index_answer_sources_on_created_at"
  end

  create_table "answers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "question_id", null: false
    t.string "message", null: false
    t.string "rephrased_question"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "status", null: false, enum_type: "answer_status"
    t.string "error_message"
    t.enum "answer_guardrails_status", enum_type: "guardrails_status"
    t.string "answer_guardrails_failures", default: [], array: true
    t.enum "question_routing_label", enum_type: "question_routing_label"
    t.float "question_routing_confidence_score"
    t.jsonb "metrics"
    t.jsonb "llm_responses"
    t.enum "jailbreak_guardrails_status", enum_type: "guardrails_status"
    t.enum "question_routing_guardrails_status", enum_type: "guardrails_status"
    t.string "question_routing_guardrails_failures", default: [], array: true
    t.enum "completeness", enum_type: "answer_completeness"
    t.string "forbidden_terms_detected", default: [], null: false, array: true
    t.index ["created_at"], name: "index_answers_on_created_at"
    t.index ["question_id"], name: "index_answers_on_question_id", unique: true
  end

  create_table "base_path_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "base_path", null: false
    t.bigint "payload_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_path"], name: "index_base_path_versions_on_base_path", unique: true
  end

  create_table "bigquery_exports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "exported_until", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exported_until"], name: "index_bigquery_exports_on_exported_until", unique: true
  end

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "signon_user_id"
    t.enum "source", default: "web", null: false, enum_type: "conversation_source"
    t.string "end_user_id"
    t.index ["created_at"], name: "index_conversations_on_created_at"
    t.index ["signon_user_id"], name: "index_conversations_on_signon_user_id"
  end

  create_table "questions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "conversation_id", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "answer_strategy", null: false
    t.string "unsanitised_message"
    t.index ["conversation_id"], name: "index_questions_on_conversation_id"
    t.index ["created_at"], name: "index_questions_on_created_at"
  end

  create_table "settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "singleton_guard", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "api_access_enabled", default: true
    t.boolean "web_access_enabled", default: true
    t.index ["singleton_guard"], name: "index_settings_on_singleton_guard", unique: true
  end

  create_table "settings_audits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "action", null: false
    t.string "author_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_settings_audits_on_created_at"
    t.index ["user_id"], name: "index_settings_audits_on_user_id"
  end

  create_table "signon_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "app_name"
    t.string "permissions", default: [], array: true
    t.boolean "remotely_signed_out", default: false
    t.boolean "disabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "answer_analysis_answer_relevancy_runs", "answers", on_delete: :cascade
  add_foreign_key "answer_analysis_topics", "answers", on_delete: :cascade
  add_foreign_key "answer_feedback", "answers", on_delete: :cascade
  add_foreign_key "answer_sources", "answer_source_chunks", on_delete: :restrict
  add_foreign_key "answer_sources", "answers", on_delete: :cascade
  add_foreign_key "answers", "questions", on_delete: :cascade
  add_foreign_key "conversations", "signon_users", on_delete: :restrict
  add_foreign_key "questions", "conversations"
  add_foreign_key "settings_audits", "signon_users", column: "user_id", on_delete: :nullify
end

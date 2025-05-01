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

ActiveRecord::Schema[8.0].define(version: 2025_05_01_150559) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "answer_status", ["answered", "banned", "clarification", "error_answer_guardrails", "error_answer_service_error", "error_context_length_exceeded", "error_jailbreak_guardrails", "error_non_specific", "error_question_routing_guardrails", "error_timeout", "guardrails_answer", "guardrails_forbidden_terms", "guardrails_jailbreak", "guardrails_question_routing", "unanswerable_llm_cannot_answer", "unanswerable_no_govuk_content", "unanswerable_question_routing"]
  create_enum "deleted_early_access_user_deletion_type", ["unsubscribe", "admin"]
  create_enum "deleted_waiting_list_user_deletion_type", ["unsubscribe", "admin", "promotion"]
  create_enum "early_access_user_source", ["admin_added", "instant_signup", "admin_promoted", "delayed_signup"]
  create_enum "guardrails_status", ["pass", "fail", "error"]
  create_enum "question_routing_label", ["about_mps", "advice_opinions_predictions", "character_fun", "genuine_rag", "gov_transparency", "greetings", "harmful_vulgar_controversy", "multi_questions", "negative_acknowledgement", "non_english", "personal_info", "positive_acknowledgement", "vague_acronym_grammar"]
  create_enum "settings_downtime_type", ["temporary", "permanent"]
  create_enum "ur_question_found_chat", ["govuk_website", "govuk_blog", "social_media", "news", "personal_contact", "professional_contact", "official_government_announcement", "search_engine", "other"]
  create_enum "ur_question_reason_for_visit", ["find_specific_answer", "complete_task", "understand_process", "research_topic", "other"]
  create_enum "ur_question_user_description", ["business_owner_or_self_employed", "starting_business_or_becoming_self_employed", "business_advisor", "business_administrator", "none"]
  create_enum "waiting_list_users_source", ["admin_added", "insufficient_instant_places"]

  create_table "answer_feedback", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "answer_id", null: false
    t.boolean "useful", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_answer_feedback_on_answer_id", unique: true
    t.index ["created_at"], name: "index_answer_feedback_on_created_at"
  end

  create_table "answer_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "answer_id", null: false
    t.string "exact_path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "relevancy", null: false
    t.string "title", null: false
    t.string "content_chunk_id", null: false
    t.string "content_chunk_digest", null: false
    t.string "base_path", null: false
    t.string "heading"
    t.boolean "used", default: true
    t.index ["answer_id", "relevancy"], name: "index_answer_sources_on_answer_id_and_relevancy", unique: true
    t.index ["answer_id"], name: "index_answer_sources_on_answer_id"
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
    t.uuid "early_access_user_id"
    t.uuid "signon_user_id"
    t.index ["created_at"], name: "index_conversations_on_created_at"
    t.index ["early_access_user_id"], name: "index_conversations_on_early_access_user_id"
    t.index ["signon_user_id"], name: "index_conversations_on_signon_user_id"
  end

  create_table "deleted_early_access_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "login_count", default: 0
    t.enum "deletion_type", null: false, enum_type: "deleted_early_access_user_deletion_type"
    t.enum "user_source", null: false, enum_type: "early_access_user_source"
    t.datetime "user_created_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "deleted_by_signon_user_id"
  end

  create_table "deleted_waiting_list_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "deletion_type", null: false, enum_type: "deleted_waiting_list_user_deletion_type"
    t.enum "user_source", null: false, enum_type: "waiting_list_users_source"
    t.datetime "user_created_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "deleted_by_signon_user_id"
  end

  create_table "early_access_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.citext "email", null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "revoked_at"
    t.enum "source", null: false, enum_type: "early_access_user_source"
    t.enum "user_description", enum_type: "ur_question_user_description"
    t.enum "reason_for_visit", enum_type: "ur_question_reason_for_visit"
    t.integer "questions_count", default: 0
    t.string "revoked_reason"
    t.boolean "onboarding_completed", default: false, null: false
    t.integer "individual_question_limit"
    t.string "unsubscribe_token", default: -> { "gen_random_uuid()" }, null: false
    t.integer "login_count", default: 0
    t.enum "found_chat", enum_type: "ur_question_found_chat"
    t.datetime "shadow_banned_at"
    t.string "shadow_banned_reason"
    t.integer "bannable_action_count", default: 0, null: false
    t.datetime "restored_at"
    t.string "restored_reason"
    t.boolean "previous_sign_up_denied", default: false, null: false
    t.index ["email"], name: "index_early_access_users_on_email", unique: true
  end

  create_table "passwordless_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "authenticatable_type"
    t.uuid "authenticatable_id"
    t.datetime "timeout_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "claimed_at"
    t.string "token_digest", null: false
    t.uuid "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authenticatable_type", "authenticatable_id"], name: "authenticatable"
    t.index ["identifier"], name: "index_passwordless_sessions_on_identifier", unique: true
  end

  create_table "questions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "conversation_id", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "answer_strategy", default: "openai_structured_answer", null: false
    t.string "unsanitised_message"
    t.index ["conversation_id"], name: "index_questions_on_conversation_id"
    t.index ["created_at"], name: "index_questions_on_created_at"
  end

  create_table "settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "singleton_guard", default: 0
    t.integer "instant_access_places", default: 0
    t.integer "delayed_access_places", default: 0
    t.boolean "sign_up_enabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public_access_enabled", default: true
    t.enum "downtime_type", default: "temporary", enum_type: "settings_downtime_type"
    t.integer "max_waiting_list_places", default: 1000, null: false
    t.integer "waiting_list_promotions_per_run", default: 25, null: false
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

  create_table "waiting_list_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.citext "email", null: false
    t.enum "user_description", enum_type: "ur_question_user_description"
    t.enum "reason_for_visit", enum_type: "ur_question_reason_for_visit"
    t.enum "source", null: false, enum_type: "waiting_list_users_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unsubscribe_token", default: -> { "gen_random_uuid()" }, null: false
    t.enum "found_chat", enum_type: "ur_question_found_chat"
    t.boolean "previous_sign_up_denied", default: false, null: false
    t.index ["email"], name: "index_waiting_list_users_on_email", unique: true
  end

  add_foreign_key "answer_feedback", "answers", on_delete: :cascade
  add_foreign_key "answer_sources", "answers", on_delete: :cascade
  add_foreign_key "answers", "questions", on_delete: :cascade
  add_foreign_key "conversations", "signon_users", on_delete: :restrict
  add_foreign_key "questions", "conversations"
  add_foreign_key "settings_audits", "signon_users", column: "user_id", on_delete: :nullify
end

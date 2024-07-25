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

ActiveRecord::Schema[7.1].define(version: 2024_07_23_130415) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "output_guardrails_status", ["pass", "fail", "error"]
  create_enum "status", ["success", "error_non_specific", "error_answer_service_error", "abort_forbidden_words", "error_context_length_exceeded", "abort_no_govuk_content", "abort_timeout", "abort_output_guardrails", "error_output_guardrails"]

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
    t.string "content_chunk_id"
    t.string "content_chunk_digest"
    t.string "base_path"
    t.string "heading"
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
    t.enum "status", null: false, enum_type: "status"
    t.string "error_message"
    t.enum "output_guardrail_status", enum_type: "output_guardrails_status"
    t.string "output_guardrail_failures", default: [], array: true
    t.string "output_guardrail_llm_response"
    t.string "llm_response"
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

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_conversations_on_created_at"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "questions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "conversation_id", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "answer_strategy", null: false
    t.index ["conversation_id"], name: "index_questions_on_conversation_id"
    t.index ["created_at"], name: "index_questions_on_created_at"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

  add_foreign_key "answer_feedback", "answers", on_delete: :cascade
  add_foreign_key "answer_sources", "answers", on_delete: :cascade
  add_foreign_key "answers", "questions", on_delete: :cascade
  add_foreign_key "questions", "conversations"
end

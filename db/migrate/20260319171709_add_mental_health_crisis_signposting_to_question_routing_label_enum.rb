class AddMentalHealthCrisisSignpostingToQuestionRoutingLabelEnum < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :question_routing_label, "mental_health_crisis_signposting"
  end
end

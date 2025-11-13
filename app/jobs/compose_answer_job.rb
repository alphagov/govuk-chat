class ComposeAnswerJob < ApplicationJob
  queue_as :answer

  def perform(question_id)
    question = Question.includes(:answer, :conversation).find(question_id)

    simulated_response = answer_html.split(" ").map { |word| "#{word} " }
    sleep 2
    question.create_answer(message: simulated_response.join, status: "answered")
    simulated_response.each do |chunk|
      ActionCable.server.broadcast("chat_#{question.conversation.id}", { question_id: question.id, message: chunk })
      sleep 0.05
    end

    ActionCable.server.broadcast("chat_#{question.conversation.id}", { question_id: question.id, finished: true })
  end

private

  def answer_html
    <<~HTML
      <p>When renewing your driving licence, you do not need to send your old licence back to DVLA in most cases.</p>
      <p>However, there are some specific situations where you must send your old licence to DVLA:</p>
      <ul>
        <li>if you find your old licence after applying for or receiving a replacement for a lost, stolen, damaged or destroyed licence</li>
        <li>if DVLA writes to you asking for your licence (for example, if you're a new driver with 6 or more penalty points, have been disqualified, or have changed your address)</li>
        <li>after getting a new lorry or bus licence, if you have not already sent your old licence</li>
      </ul>
      <p>For standard licence renewals, you can keep your current licence while applying and do not need to return it unless specifically asked by DVLA.</p>
      <p>Check the <a href='https://www.gov.uk/renew-driving-licence#apply-at-a-post-office'>guidance on renewing your driving licence</a> for more information about the renewal process.</p>
    HTML
  end
end

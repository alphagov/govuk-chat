window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.form = this.module.querySelector('.js-conversation-form')
    }

    init () {
      this.module.addEventListener('submit', e => this.handleFormSubmission(e))
    }

    async handleFormSubmission (event) {
      event.preventDefault()

      // TODO: dispatch `question-pending` event

      try {
        const formData = new FormData(this.form)
        const response = await fetch(this.form.action, {
          method: 'POST',
          body: formData,
          headers: {
            Accept: 'application/json'
          }
        })
        await this.handleQuestionResponse(response)
      } catch (error) {
        console.error(error)
        this.form.submit()
      }
    }

    // TODO: handle different response statuses here
    async handleQuestionResponse (response) {
      if (response.status === 201) {
        const questionResponse = await response.json()
        // TODO: remove and update UI with `response.question_html`
        this.redirectToAnswerUrl(questionResponse.answer_url)
      } else {
        throw new Error(`Unexpected response status: ${response.status}`)
      }
    }

    redirectToAnswerUrl (url) {
      window.location.href = url
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

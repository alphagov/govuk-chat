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

    async handleQuestionResponse (response) {
      switch (response.status) {
        case 201: {
          const responseJson = await response.json()
          // TODO: remove and update UI with `response.question_html`
          this.redirectToAnswerUrl(responseJson.answer_url)
          break
        }
        case 422: {
          const responseJson = await response.json()
          this.form.dispatchEvent(
            new CustomEvent('question-rejected', {
              detail: { errorMessages: responseJson.error_messages }
            })
          )
          break
        }
        default:
          throw new Error(`Unexpected response status: ${response.status}`)
      }
    }

    redirectToAnswerUrl (url) {
      window.location.href = url
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

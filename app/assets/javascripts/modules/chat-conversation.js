window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.form = this.module.querySelector('.js-conversation-form')
      this.conversationList = this.module.querySelector('.js-conversation-list')
    }

    init () {
      this.module.addEventListener('submit', e => this.handleFormSubmission(e))
    }

    async handleFormSubmission (event) {
      event.preventDefault()

      try {
        this.form.dispatchEvent(new Event('question-pending'))

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
          this.conversationList.insertAdjacentHTML('beforeend', responseJson.question_html)

          this.form.dispatchEvent(new Event('question-accepted'))

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

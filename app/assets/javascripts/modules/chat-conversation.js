window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.form = this.module.querySelector('.js-conversation-form')
      this.conversationList = this.module.querySelector('.js-conversation-list')
      this.pendingAnswerUrl = this.module.dataset.pendingAnswerUrl
      this.ANSWER_INTERVAL = 500
    }

    init () {
      this.module.addEventListener('submit', e => this.handleFormSubmission(e))

      if (!this.pendingAnswerUrl) return

      const loadPendingAnswer = () => {
        this.checkAnswer()
        this.form.dispatchEvent(new Event('question-accepted'))
      }

      if (this.form.dataset.conversationFormModuleStarted) {
        loadPendingAnswer()
      } else {
        this.form.addEventListener('init', loadPendingAnswer)
      }
    }

    async handleFormSubmission (event) {
      if (event.submitter && event.submitter.className.includes('app-c-answer-feedback-form__button')) {
        return
      }

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

        if (this.pendingAnswerUrl) {
          setTimeout(() => this.checkAnswer(), this.ANSWER_INTERVAL)
        }
      } catch (error) {
        console.error(error)
        this.form.submit()
      }
    }

    async handleQuestionResponse (response) {
      switch (response.status) {
        case 201: {
          const responseJson = await response.json()

          this.conversationList.insertAdjacentHTML('beforeend', responseJson.question_html)

          this.form.dispatchEvent(new Event('question-accepted'))

          this.pendingAnswerUrl = responseJson.answer_url
          break
        }
        case 422: {
          const responseJson = await response.json()

          this.form.dispatchEvent(
            new CustomEvent('question-rejected', {
              detail: { errorMessages: responseJson.error_messages }
            })
          )

          this.pendingAnswerUrl = null
          break
        }
        default:
          throw new Error(`Unexpected response status: ${response.status}`)
      }
    }

    async checkAnswer () {
      if (!this.pendingAnswerUrl) return

      try {
        const response = await fetch(this.pendingAnswerUrl, { headers: { Accept: 'application/json' } })
        switch (response.status) {
          case 200: {
            const responseJson = await response.json()
            this.conversationList.insertAdjacentHTML('beforeend', responseJson.answer_html)
            this.pendingAnswerUrl = null
            this.form.dispatchEvent(new Event('answer-received'))
            break
          }
          case 202: {
            setTimeout(() => this.checkAnswer(), this.ANSWER_INTERVAL)
            break
          }
          default:
            throw new Error(`Unexpected response status: ${response.status}`)
        }
      } catch (error) {
        console.error(error)
        this.redirect(this.pendingAnswerUrl)
      }
    }

    redirect (url) {
      window.location.href = url
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

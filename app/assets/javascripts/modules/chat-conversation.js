window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.flashAlert = this.module.querySelector('.js-conversation-alert')
      this.formComponent = this.module.querySelector('.js-conversation-form-wrapper')
      this.form = this.module.querySelector('.js-conversation-form')
      this.conversationList = this.module.querySelector('.js-conversation-list')
      this.pendingAnswerUrl = this.module.dataset.pendingAnswerUrl
      this.ANSWER_INTERVAL = 500
    }

    init () {
      if (this.flashAlert) this.flashAlert.classList.add('js-hidden')

      this.formComponent.addEventListener('submit', e => this.handleFormSubmission(e))

      if (!this.pendingAnswerUrl) return

      const loadPendingAnswer = () => {
        this.checkAnswer()
        this.formComponent.dispatchEvent(new Event('question-accepted'))
      }

      if (this.formComponent.dataset.conversationFormModuleStarted) {
        loadPendingAnswer()
      } else {
        this.formComponent.addEventListener('init', loadPendingAnswer)
      }
    }

    async handleFormSubmission (event) {
      event.preventDefault()

      try {
        this.formComponent.dispatchEvent(new Event('question-pending'))

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
          this.scrollToMessage(this.conversationList.lastElementChild)

          this.formComponent.dispatchEvent(new Event('question-accepted'))

          this.pendingAnswerUrl = responseJson.answer_url
          break
        }
        case 422: {
          const responseJson = await response.json()

          this.formComponent.dispatchEvent(
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
            this.scrollToMessage(this.conversationList.lastElementChild)

            window.GOVUK.modules.start(this.conversationList)

            this.pendingAnswerUrl = null
            this.formComponent.dispatchEvent(new Event('answer-received'))
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

    scrollToMessage (lastElementChild) {
      lastElementChild.scrollIntoView()
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

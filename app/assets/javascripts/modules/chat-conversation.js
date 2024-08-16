window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.formComponent = this.module.querySelector('.js-conversation-form-wrapper')
      this.form = this.module.querySelector('.js-conversation-form')
      this.messageLists = new Modules.ConversationMessageLists(this.module.querySelector('.js-conversation-message-lists'))
      this.pendingAnswerUrl = this.module.dataset.pendingAnswerUrl
      this.ANSWER_INTERVAL = 500
    }

    init () {
      this.module.addEventListener('conversation-append', e => this.conversationAppend(e))
      this.formComponent.addEventListener('submit', e => this.handleFormSubmission(e))

      // existing new messages indicates we are in onboarding
      if (this.messageLists.hasNewMessages()) {
        this.formComponent.classList.add('govuk-visually-hidden')
        this.messageLists.progressivelyDiscloseMessages().then(() => {
          this.formComponent.classList.remove('govuk-visually-hidden')
          this.messageLists.scrollToLastNewMessage()
        })
      } else {
        this.messageLists.scrollToLastMessageInHistory()
      }

      if (!this.pendingAnswerUrl) return

      const loadPendingAnswer = () => {
        this.messageLists.renderAnswerLoading()
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

        this.messageLists.moveNewMessagesToHistory()
        this.messageLists.renderQuestionLoading()

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
          this.messageLists.renderAnswerLoading()
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
          this.messageLists.renderQuestion(responseJson.question_html)

          this.formComponent.dispatchEvent(new Event('question-accepted'))

          this.pendingAnswerUrl = responseJson.answer_url
          break
        }
        case 422: {
          const responseJson = await response.json()
          this.messageLists.resetQuestionLoading()

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

            this.messageLists.renderAnswer(responseJson.answer_html)

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

    async conversationAppend (event) {
      this.formComponent.classList.add('govuk-visually-hidden')
      await this.messageLists.appendNewProgressivelyDisclosedMessages(event.detail.html)
      this.formComponent.classList.remove('govuk-visually-hidden')
      this.messageLists.scrollToLastNewMessage()
    }

    redirect (url) {
      window.location.href = url
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

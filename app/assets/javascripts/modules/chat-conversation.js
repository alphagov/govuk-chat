window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.conversationFormRegion = this.module.querySelector('.js-conversation-form-region')
      this.formContainer = this.module.querySelector('.js-question-form-container')
      this.form = this.module.querySelector('.js-question-form')
      this.messageLists = new Modules.ConversationMessageLists(this.module.querySelector('.js-conversation-message-lists'))
      this.pendingAnswerUrl = this.module.dataset.pendingAnswerUrl
      this.ANSWER_INTERVAL = 500
    }

    init () {
      this.module.addEventListener('conversation-append', e => this.conversationAppend(e))
      this.formContainer.addEventListener('submit', e => this.handleFormSubmission(e))

      // existing new messages indicates we are in onboarding
      if (this.messageLists.hasNewMessages()) {
        this.conversationFormRegion.classList.add('govuk-visually-hidden')
        this.messageLists.progressivelyDiscloseMessages().then(() => {
          this.conversationFormRegion.classList.add('app-conversation-layout__form-region--slide-in')
          this.conversationFormRegion.classList.remove('govuk-visually-hidden')
          this.messageLists.scrollToLastNewMessage()
        })
      } else {
        this.messageLists.scrollToLastMessageInHistory()
      }

      if (!this.pendingAnswerUrl) return

      const loadPendingAnswer = () => {
        this.messageLists.renderAnswerLoading()
        this.checkAnswer()
        this.formContainer.dispatchEvent(new Event('question-accepted'))
      }

      if (this.formContainer.dataset.conversationFormModuleStarted) {
        loadPendingAnswer()
      } else {
        this.formContainer.addEventListener('init', loadPendingAnswer)
      }
    }

    async handleFormSubmission (event) {
      event.preventDefault()

      try {
        this.formContainer.dispatchEvent(new Event('question-pending'))

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

          this.formContainer.dispatchEvent(new Event('question-accepted'))

          this.pendingAnswerUrl = responseJson.answer_url
          break
        }
        case 422: {
          const responseJson = await response.json()
          this.messageLists.resetQuestionLoading()

          this.formContainer.dispatchEvent(
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

            this.formContainer.dispatchEvent(new Event('answer-received'))
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
      this.conversationFormRegion.classList.add('govuk-visually-hidden')
      this.conversationFormRegion.classList.remove('app-conversation-layout__form-region--slide-in')
      await this.messageLists.appendNewProgressivelyDisclosedMessages(event.detail.html)
      this.conversationFormRegion.classList.add('app-conversation-layout__form-region--slide-in')
      this.conversationFormRegion.classList.remove('app-conversation-layout__form-region--slide-out')
      this.conversationFormRegion.classList.remove('govuk-visually-hidden')
      this.messageLists.scrollToLastNewMessage()
    }

    redirect (url) {
      window.location.href = url
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

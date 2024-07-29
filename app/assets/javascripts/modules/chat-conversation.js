window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.formComponent = this.module.querySelector('.js-conversation-form-wrapper')
      this.form = this.module.querySelector('.js-conversation-form')
      this.conversationList = this.module.querySelector('.js-conversation-list')
      this.pendingAnswerUrl = this.module.dataset.pendingAnswerUrl
      this.ANSWER_INTERVAL = 500

      this.QUESTION_LOADNG_TIMEOUT = 500
      this.loadingAnswerTemplate = this.module.querySelector('#js-loading-answer')
      this.loadingQuestionTemplate = this.module.querySelector('#js-loading-question')
    }

    init () {
      // if there is an existing conversation on page load, scroll to the latest message
      if (this.conversationList.children.length > 0) {
        this.scrollToMessage(this.conversationList.lastElementChild)
      }

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

        let questionLoadingElement
        const loadingTimeout = setTimeout(() => {
          questionLoadingElement = this.startLoading(this.loadingQuestionTemplate)
        }, this.QUESTION_LOADNG_TIMEOUT)

        const formData = new FormData(this.form)
        const response = await fetch(this.form.action, {
          method: 'POST',
          body: formData,
          headers: {
            Accept: 'application/json'
          }
        })
        clearTimeout(loadingTimeout)
        if (questionLoadingElement) this.conversationList.removeChild(questionLoadingElement)
        await this.handleQuestionResponse(response)
        this.answerLoadingElement = this.startLoading(this.loadingAnswerTemplate)

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

            if (this.answerLoadingElement) this.conversationList.removeChild(this.answerLoadingElement)

            this.conversationList.insertAdjacentHTML('beforeend', responseJson.answer_html)
            const answer = this.conversationList.lastElementChild
            answer.classList.add('app-c-conversation-message--fade-in')

            window.GOVUK.modules.start(this.conversationList)

            this.pendingAnswerUrl = null

            this.formComponent.dispatchEvent(new Event('answer-received'))
            this.scrollToMessage(answer)
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

    startLoading (template) {
      this.conversationList.appendChild(template.content.cloneNode(true))

      const loadingElement = this.conversationList.lastElementChild
      this.scrollToMessage(loadingElement)

      return loadingElement
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

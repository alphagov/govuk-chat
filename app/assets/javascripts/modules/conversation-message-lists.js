window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ConversationMessageLists {
    constructor (module) {
      this.PROGRESSIVE_DISCLOSURE_DELAY = parseInt(module.dataset.progressiveDisclosureDelay, 10)
      this.MESSAGE_SELECTOR = '.js-conversation-message'
      this.QUESTION_LOADING_TIMEOUT = 500

      this.module = module
      this.messageHistoryList = module.querySelector('.js-conversation-message-history-list')
      this.newMessagesContainer = module.querySelector('.js-new-conversation-messages-container')
      this.newMessagesList = module.querySelector('.js-new-conversation-messages-list')
      this.loadingQuestionTemplate = this.module.querySelector('.js-loading-question')
      this.loadingAnswerTemplate = this.module.querySelector('.js-loading-answer')

      this.questionLoadingTimeout = null
      this.questionLoadingElement = null
      this.answerLoadingElement = null
    }

    hasNewMessages () {
      return this.newMessagesList.querySelector(this.MESSAGE_SELECTOR) !== null
    }

    progressivelyDiscloseMessages () {
      return new Promise((resolve, _reject) => {
        this.hideNewMessagesAfterFirst()
        const firstMessage = this.newMessagesList.querySelector(this.MESSAGE_SELECTOR)
        if (firstMessage) this.scrollIntoView(firstMessage)

        const nextMessageSelector = `${this.MESSAGE_SELECTOR}.govuk-visually-hidden`

        const interval = window.setInterval(() => {
          const messageToShow = this.newMessagesList.querySelector(nextMessageSelector)
          if (!messageToShow) {
            window.clearInterval(interval)
            resolve()
            return
          }

          messageToShow.classList.add('app-c-conversation-message--fade-in')
          messageToShow.classList.remove('govuk-visually-hidden')
          this.scrollIntoView(messageToShow)
        }, this.PROGRESSIVE_DISCLOSURE_DELAY)
      })
    }

    async appendNewProgressivelyDisclosedMessages (messagesHtml) {
      this.newMessagesList.innerHTML = messagesHtml
      this.newMessagesContainer.focus()
      await this.progressivelyDiscloseMessages()
    }

    scrollToLastNewMessage () {
      const message = this.newMessagesList.querySelector(`${this.MESSAGE_SELECTOR}:last-child`)
      if (message) this.scrollIntoView(message)
    }

    scrollToLastMessageInHistory () {
      const message = this.messageHistoryList.querySelector(`${this.MESSAGE_SELECTOR}:last-child`)
      if (message) this.scrollIntoView(message)
    }

    moveNewMessagesToHistory () {
      this.newMessagesList.querySelectorAll(this.MESSAGE_SELECTOR).forEach(message => {
        message.classList.remove('app-c-conversation-message--fade-in')
        this.messageHistoryList.appendChild(message)
      })
    }

    renderQuestionLoading () {
      this.questionLoadingTimeout = window.setTimeout(() => {
        this.questionLoadingElement = this.appendLoadingElement(this.loadingQuestionTemplate)
      }, this.QUESTION_LOADING_TIMEOUT)
    }

    resetQuestionLoading () {
      if (this.questionLoadingTimeout) window.clearTimeout(this.questionLoadingTimeout)
      if (this.questionLoadingElement) {
        this.newMessagesList.removeChild(this.questionLoadingElement)
        this.questionLoadingElement = null
      }
    }

    renderQuestion (questionHtml) {
      const toFadeIn = this.questionLoadingElement === null
      this.resetQuestionLoading()
      this.newMessagesList.insertAdjacentHTML('beforeend', questionHtml)
      const question = this.newMessagesList.lastElementChild
      if (toFadeIn) question.classList.add('app-c-conversation-message--fade-in')
      this.scrollIntoView(question)
    }

    renderAnswerLoading () {
      this.answerLoadingElement = this.appendLoadingElement(this.loadingAnswerTemplate)
    }

    renderAnswer (answerHtml) {
      if (this.answerLoadingElement) this.newMessagesList.removeChild(this.answerLoadingElement)

      this.newMessagesList.insertAdjacentHTML('beforeend', answerHtml)
      this.newMessagesContainer.focus()
      window.GOVUK.modules.start(this.newMessagesList)
      this.scrollIntoView(this.newMessagesList.lastElementChild)
    }

    // private methods

    appendLoadingElement (template) {
      this.newMessagesList.appendChild(template.content.cloneNode(true))

      const loadingElement = this.newMessagesList.lastElementChild
      loadingElement.classList.add('app-c-conversation-message--fade-in')
      this.scrollIntoView(loadingElement)

      return loadingElement
    }

    hideNewMessagesAfterFirst () {
      const messages = this.newMessagesList.querySelectorAll(`${this.MESSAGE_SELECTOR}:not(:first-child)`)
      messages.forEach(element => element.classList.add('govuk-visually-hidden'))
    }

    scrollIntoView (element) {
      element.scrollIntoView()
    }
  }

  Modules.ConversationMessageLists = ConversationMessageLists
})(window.GOVUK.Modules)

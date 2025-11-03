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
      this.answerHTML = null
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

        const showMessage = () => {
          const messageToShow = this.newMessagesList.querySelector(nextMessageSelector)
          if (!messageToShow) {
            resolve()
            return
          }

          messageToShow.classList.add('app-c-conversation-message--fade-in')
          messageToShow.classList.remove('govuk-visually-hidden')
          this.scrollIntoView(messageToShow)
          window.setTimeout(showMessage, this.PROGRESSIVE_DISCLOSURE_DELAY)
        }

        window.setTimeout(showMessage, this.PROGRESSIVE_DISCLOSURE_DELAY / 2)
      })
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

   renderAnswer(html) {
      if (this.answerLoadingElement) {
        this.newMessagesList.removeChild(this.answerLoadingElement);
        this.answerLoadingElement = null;
      }
      let lastMessage = this.newMessagesList.lastElementChild;
      let lastMessageBody = lastMessage ? lastMessage.querySelector('.app-c-conversation-message__body') : null;
      let pTag = null

      if (
        lastMessage &&
        lastMessageBody &&
        lastMessageBody.classList.contains('app-c-conversation-message__body--govuk-message')
      ) {
        pTag = lastMessageBody.querySelector('.govuk-govspeak p')
      }

      if (!pTag) {
        const list = document.createElement('li')
        list.classList.add('app-c-conversation-message', 'js-conversation-message')
        this.newMessagesList.appendChild(list)

        const messageDiv = document.createElement('div');
        messageDiv.classList.add('app-c-conversation-message__message', 'app-c-conversation-message__message--govuk-message')
        list.appendChild(messageDiv);

        const messageBody = document.createElement('div')
        messageBody.classList.add('app-c-conversation-message__body', 'app-c-conversation-message__body--govuk-message')
        messageDiv.appendChild(messageBody)

        const identifierSpan = document.createElement('span')
        identifierSpan.classList.add('app-c-conversation-message__identifier')
        identifierSpan.textContent = 'GOV.UK Chat'
        messageBody.appendChild(identifierSpan)

        const answerDiv = document.createElement('div')
        answerDiv.classList.add('app-c-conversation-message__answer')
        messageBody.appendChild(answerDiv)

        const govspeakDiv = document.createElement('div')
        govspeakDiv.classList.add('gem-c-govspeak', 'govuk-govspeak', 'govuk-!-margin-bottom-0')
        answerDiv.appendChild(govspeakDiv);

        pTag = document.createElement('p')
        govspeakDiv.appendChild(pTag);
        this.answerHTML = '';
      }

      this.answerHTML += html;
      pTag.innerHTML = this.answerHTML;
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

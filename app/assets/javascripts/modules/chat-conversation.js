window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ChatConversation {
    constructor (module) {
      this.module = module
      this.conversationFormRegion = this.module.querySelector('.js-conversation-form-region')
      this.formContainer = this.module.querySelector('.js-question-form-container')
      this.form = this.module.querySelector('.js-question-form')
      this.messageLists = new Modules.ConversationMessageLists(
        this.module.querySelector('.js-conversation-message-lists')
      )
      this.conversationId = this.module.dataset.conversationId // set from backend
      this.questionId = null
      this.stopButton = this.module.querySelector('.js-stop-stream')
    }

    init() {
      this.formContainer.addEventListener('submit', e => this.handleFormSubmission(e))
      this.stopButton.addEventListener('click', e => this.stopStreaming(e))
      if (this.conversationId) {
        this.subscribeToChannel()
      }
    }

    subscribeToChannel() {
      if (!this.conversationId || !this.questionId || this.chatSubscription) return

      this.chatSubscription = window.GOVUK.consumer.subscriptions.create(
        { channel: "ChatChannel", conversation_id: this.conversationId, question_id: this.questionId },
        {
          connected: () => {
            this.hideReconnectingMessage()
            if (this.hasPreviouslyConnected) {
              console.log(`Reconnected to conversation ${this.conversationId} and question ${this.questionId} channel.`)
              this.rebroadcastMissedAnswer()
            } else {
              console.log(`Connected to conversation ${this.conversationId} and question ${this.questionId} channel.`)
              this.hasPreviouslyConnected = true
            }
          },
          disconnected: () => {
            console.log(`Disconnected from conversation ${this.conversationId} and question ${this.questionId}`)
            this.showReconnectingMessage()
          },
          received: (data) => {
            if (data.message) {
              this.messageLists.renderAnswer(data.message)
            }

            if (data.finished) {
              console.log(`Disconnecting from conversation ${this.conversationId} and question ${this.questionId} channel.`)
              this.unsubscribeFromChannel()
            }
          }
        }
      )
    }

    unsubscribeFromChannel() {
      if (this.chatSubscription) {
        this.chatSubscription.unsubscribe()
        this.hasPreviouslyConnected = false
        this.questionId = null
        this.chatSubscription = null
      }
    }

    stopStreaming() {
      if (this.chatSubscription) {
        if (this.messageLists.answerLoadingElement) {
          this.messageLists.newMessagesList.removeChild(this.messageLists.answerLoadingElement);
          this.messageLists.answerLoadingElement = null;
        }

        console.log(`Disconnecting from conversation ${this.conversationId} and question ${this.questionId} channel.`)
        this.unsubscribeFromChannel()
        const warning = document.createElement('div')
        warning.className = 'gem-c-warning-text govuk-warning-text js-conversation-message';

        const icon = document.createElement('span')
        icon.className = 'govuk-warning-text__icon'
        icon.setAttribute('aria-hidden', 'true')
        icon.textContent = '!'

        const strong = document.createElement('strong')
        strong.className = 'govuk-warning-text__text'

        const hidden = document.createElement('span')
        hidden.className = 'govuk-visually-hidden'
        hidden.textContent = 'Warning'

        strong.appendChild(hidden)
        strong.append(' Streaming has been stopped or cancelled.')
        warning.appendChild(icon)
        warning.appendChild(strong)

        this.messageLists.newMessagesList.appendChild(warning)
        this.messageLists.scrollIntoView(warning)
      }
    }

    showReconnectingMessage() {
      if (!this.reconnectingElement) {
        const list = document.createElement('li');
        list.className = 'app-c-conversation-message js-conversation-message'

        const divBody = document.createElement('div');
        divBody.className = 'app-c-conversation-message__body app-c-conversation-message__body--loading-message'
        divBody.innerHTML = `
          <p class="app-c-conversation-message__loading-text govuk-body">
            Attempting to reconnect<span class="app-c-conversation-message__loading-ellipsis" aria-hidden="true">...</span>
          </p>
        `
        list.appendChild(divBody)

        this.reconnectingElement = list
        this.messageLists.newMessagesList.appendChild(list)
        this.messageLists.scrollIntoView(list)
      }
    }

    hideReconnectingMessage() {
      if (this.reconnectingElement) {
        this.messageLists.newMessagesList.removeChild(this.reconnectingElement)
        this.reconnectingElement = null
      }
    }

    async rebroadcastMissedAnswer() {
      if (!this.conversationId || !this.questionId|| !this.chatSubscription) return

      console.log(`Attempting to retrieve missed answer for question ${this.questionId}.`)
      await this.chatSubscription.perform("answer", {
        current_html: this.messageLists.answerHTML
      })
    }

    async handleFormSubmission(event) {
      event.preventDefault()

      this.messageLists.moveNewMessagesToHistory()
      this.messageLists.renderQuestionLoading()

      const formData = new FormData(this.form)
      const response = await fetch(this.form.action, {
        method: 'POST',
        body: formData,
        headers: { Accept: 'application/json' }
      })

      const responseJson = await response.json()

      if (response.status === 201) {
        this.messageLists.renderQuestion(responseJson.question_html)
        this.messageLists.renderAnswerLoading()
        this.conversationId = responseJson.conversation_id
        this.questionId = responseJson.question_id
        this.subscribeToChannel()
      } else if (response.status === 422) {
        this.messageLists.resetQuestionLoading()
        console.error(responseJson.error_messages)
      }

      this.form.reset()
    }
  }

  Modules.ChatConversation = ChatConversation
})(window.GOVUK.Modules)

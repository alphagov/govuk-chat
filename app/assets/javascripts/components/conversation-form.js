window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class ConversationForm {
    constructor (module) {
      this.module = module
      this.input = module.querySelector('.js-conversation-form-input')
      this.button = module.querySelector('.js-conversation-form-button')
    }

    init () {
      this.module.addEventListener('question-pending', () => this.handleQuestionPending())
      this.module.addEventListener('question-accepted', () => this.handleQuestionAccepted())
      this.module.addEventListener('question-rejected', () => this.handleQuestionRejected())
      this.module.addEventListener('answer-received', () => this.handleAnswerReceived())
    }

    handleQuestionPending () {
      this.disableControls()
    }

    handleQuestionAccepted () {
      this.disableControls()
      this.input.value = ''
    }

    handleQuestionRejected () {
      this.enableControls()
    }

    handleAnswerReceived () {
      this.input.value = ''
      this.enableControls()
    }

    disableControls () {
      this.input.disabled = true
      this.button.disabled = true
    }

    enableControls () {
      this.input.disabled = false
      this.button.disabled = false
    }
  }

  Modules.ConversationForm = ConversationForm
})(window.GOVUK.Modules)

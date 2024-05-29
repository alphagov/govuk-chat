window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class ConversationForm {
    constructor (module) {
      this.module = module
      this.input = module.querySelector('.js-conversation-form-input')
      this.button = module.querySelector('.js-conversation-form-button')
      this.errorsWrapper = module.querySelector('.js-conversation-form-errors-wrapper')
    }

    init () {
      this.module.addEventListener('submit', e => this.handleSubmit(e))
      this.module.addEventListener('question-pending', () => this.handleQuestionPending())
      this.module.addEventListener('question-accepted', () => this.handleQuestionAccepted())
      this.module.addEventListener('question-rejected', e => this.handleQuestionRejected(e))
      this.module.addEventListener('answer-received', () => this.handleAnswerReceived())
    }

    handleSubmit (event) {
      const errors = []

      if (this.input.value.trim() === '') {
        errors.push(this.module.dataset.presenceErrorMessage)
      }

      const maxlength = parseInt(this.module.dataset.maxlength, 10)

      if (this.input.value.length > maxlength) {
        errors.push(this.module.dataset.lengthErrorMessage)
      }

      this.replaceErrors(errors)

      if (errors.length) {
        event.preventDefault()
        event.stopImmediatePropagation()
      }
    }

    handleQuestionPending () {
      this.disableControls()
    }

    handleQuestionAccepted () {
      this.disableControls()
      this.input.value = ''
    }

    handleQuestionRejected (event) {
      if (!event.detail || !event.detail.errorMessages) {
        throw new Error('expected event detail containing errorMessages')
      }

      this.replaceErrors(event.detail.errorMessages)
      this.enableControls()
    }

    handleAnswerReceived () {
      this.input.value = ''
      this.enableControls()
    }

    disableControls () {
      this.input.readOnly = true
      this.button.disabled = true
    }

    enableControls () {
      this.input.readOnly = false
      this.button.disabled = false
    }

    replaceErrors (errors) {
      this.errorsWrapper.hidden = errors.length === 0

      const elements = errors.map(error => {
        const li = document.createElement('li')
        li.innerHTML = '<span class="govuk-visually-hidden">Error:</span>'
        li.appendChild(document.createTextNode(error))
        return li
      })

      this.errorsWrapper.replaceChildren(...elements)
    }
  }

  Modules.ConversationForm = ConversationForm
})(window.GOVUK.Modules)

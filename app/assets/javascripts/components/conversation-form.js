window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class ConversationForm {
    constructor (module) {
      this.module = module
      this.form = module.querySelector('.js-conversation-form')
      this.input = module.querySelector('.js-conversation-form-input')
      this.button = module.querySelector('.js-conversation-form-button')
      this.errorsWrapper = module.querySelector('.js-conversation-form-errors-wrapper')
      this.formGroup = module.querySelector('.js-conversation-form-group')
      this.surveyLink = module.querySelector('.js-survey-link')
      this.conversationId = null
    }

    init () {
      this.form.addEventListener('submit', e => this.handleSubmit(e))
      this.module.addEventListener('question-pending', () => this.handleQuestionPending())
      this.module.addEventListener('question-accepted', () => this.handleQuestionAccepted())
      this.module.addEventListener('question-rejected', e => this.handleQuestionRejected(e))
      this.module.addEventListener('answer-received', () => this.handleAnswerReceived())
      // used to inform other components that this component is initialised.
      this.module.dispatchEvent(new Event('init'))

      new window.GOVUKFrontend.CharacterCount(this.module).init()
    }

    handleSubmit (event) {
      const errors = []

      if (this.input.value.trim() === '') {
        errors.push(this.module.dataset.presenceErrorMessage)
      }

      this.replaceErrors(errors)

      const maxlength = parseInt(this.module.dataset.maxlength, 10)
      const exceedsMaxLength = this.input.value.length > maxlength

      if (errors.length || exceedsMaxLength) {
        event.preventDefault()
        event.stopImmediatePropagation()
      }
    }

    handleQuestionPending () {
      this.disableControls()
    }

    handleQuestionAccepted () {
      this.disableControls()
      this.resetInput()
      this.updateSurveyLink()
    }

    handleQuestionRejected (event) {
      if (!event.detail || !event.detail.errorMessages) {
        throw new Error('expected event detail containing errorMessages')
      }

      this.replaceErrors(event.detail.errorMessages)
      this.enableControls()
    }

    handleAnswerReceived () {
      this.resetInput()
      this.enableControls()
    }

    disableControls () {
      this.input.readOnly = true
      this.button.disabled = true
    }

    enableControls () {
      this.input.readOnly = false
      this.button.disabled = false
      this.button.focus()
    }

    resetInput () {
      this.input.value = ''

      // Trigger keyup event so the character-count component resets and clears the count hint
      this.input.dispatchEvent(new Event('keyup'))
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

      this.toggleErrorStyles(errors.length)
    }

    toggleErrorStyles (hasErrors) {
      if (hasErrors) {
        this.input.classList.add('app-c-conversation-form__input--error')
        this.formGroup.classList.add('app-c-conversation-form__form-group--error')
      } else {
        this.input.classList.remove('app-c-conversation-form__input--error')
        this.formGroup.classList.remove('app-c-conversation-form__form-group--error')
      }
    }

    updateSurveyLink () {
      const conversationId = window.GOVUK.cookie('conversation_id')

      if (conversationId === this.conversationId) return

      const url = new URL(this.surveyLink.href)
      url.searchParams.set('conversation', conversationId)
      this.surveyLink.href = url.toString()

      this.conversationId = conversationId
    }
  }

  Modules.ConversationForm = ConversationForm
})(window.GOVUK.Modules)

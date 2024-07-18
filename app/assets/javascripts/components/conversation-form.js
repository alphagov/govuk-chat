window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class ConversationForm {
    constructor (module) {
      this.module = module
      this.form = module.querySelector('.js-conversation-form')
      this.input = module.querySelector('.js-conversation-form-input')
      this.label = module.querySelector('.js-conversation-form-label')
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
      // By default, the aria-describedby attribute references hint text and errors associated with the input.
      // Here, we set aria-described to only reference the hint text as we handle errors differently when JS is enabled
      // in order to achieve consistent behaviour (see announceErrors() for further details).
      // The error id hasn't been removed from aria-describedby in the template because we need it for when JS is
      // unavailable/disabled.
      this.input.setAttribute('aria-describedby', this.module.dataset.hintId)

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

      this.enableControls()
      this.replaceErrors(event.detail.errorMessages)
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
        li.className = 'app-c-conversation-form__error-message'
        return li
      })

      this.errorsWrapper.replaceChildren(...elements)

      this.toggleErrorStyles(errors.length)
      this.announceErrors(errors.length)
      if (errors.length) this.input.focus()
    }

    // This function changes the label of the input field to the list of error messages if errors are present.
    // This is to get errors re-announced if the same erroneous input is submitted (e.g. repeatedly submitting a blank input).
    // Aria-live won't work in this scenario because repeated errors aren't re-announced.
    announceErrors (hasErrors) {
      if (hasErrors) {
        this.label.ariaHidden = true
        this.input.setAttribute('aria-labelledby', this.errorsWrapper.id)
      } else {
        this.input.removeAttribute('aria-labelledby')
        this.label.ariaHidden = false
      }
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

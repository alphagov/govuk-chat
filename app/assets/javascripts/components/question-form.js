//= require govuk-frontend/dist/govuk/components/character-count/character-count.bundle

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class QuestionForm {
    constructor (module) {
      this.module = module
      this.form = module.querySelector('.js-question-form')
      this.input = module.querySelector('.js-question-form-input')
      this.button = module.querySelector('.js-question-form-button')
      this.buttonResponseStatus = module.querySelector('.js-question-form-button__response-status')
      this.errorsWrapper = module.querySelector('.js-question-form-errors-wrapper')
      this.formGroup = module.querySelector('.js-question-form-group')
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

      new window.GOVUKFrontend.CharacterCount(this.module) // eslint-disable-line no-new
    }

    handleSubmit (event) {
      if (this.button.hasAttribute('aria-disabled')) {
        event.preventDefault()
        event.stopImmediatePropagation()
        return
      }

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
      this.handleButtonResponseStatus(this.buttonResponseStatus.dataset.loadingQuestionText)
    }

    handleQuestionAccepted () {
      this.disableControls()
      this.resetInput()
      this.handleButtonResponseStatus(this.buttonResponseStatus.dataset.loadingAnswerText)
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
      this.toggleDisabledSettings(true)
    }

    enableControls () {
      this.input.readOnly = false
      this.toggleDisabledSettings(false)
    }

    handleButtonResponseStatus (text) {
      this.buttonResponseStatus.textContent = text
    }

    toggleDisabledSettings (isDisabled) {
      if (isDisabled) {
        this.button.setAttribute('aria-disabled', 'true')
        this.button.classList.add('app-c-blue-button--disabled')
      } else {
        this.button.removeAttribute('aria-disabled')
        this.button.classList.remove('app-c-blue-button--disabled')
        this.buttonResponseStatus.textContent = ''
      }
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
        li.className = 'app-c-question-form__error-message'
        return li
      })

      this.errorsWrapper.replaceChildren(...elements)

      this.toggleErrorStyles(errors.length)

      if (errors.length) {
        this.attachInputDescriptions(this.errorsWrapper.id)
        this.input.focus()
      } else {
        this.resetInputDescriptions()
      }
    }

    attachInputDescriptions () {
      const ids = [this.module.dataset.hintId, ...arguments].join(' ')
      this.input.setAttribute('aria-describedby', ids)
    }

    resetInputDescriptions () {
      this.input.setAttribute('aria-describedby', this.module.dataset.hintId)
    }

    toggleErrorStyles (hasErrors) {
      if (hasErrors) {
        this.input.classList.add('app-c-question-form__input--error')
        this.formGroup.classList.add('app-c-question-form__form-group--error')
      } else {
        this.input.classList.remove('app-c-question-form__input--error')
        this.formGroup.classList.remove('app-c-question-form__form-group--error')
      }
    }
  }

  Modules.QuestionForm = QuestionForm
})(window.GOVUK.Modules)

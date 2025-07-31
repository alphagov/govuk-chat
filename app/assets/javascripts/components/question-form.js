//= require govuk-frontend/dist/govuk/components/character-count/character-count.bundle

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class QuestionForm {
    constructor (module) {
      this.module = module
      this.form = module.querySelector('.js-question-form')
      this.textarea = module.querySelector('.js-question-form-textarea')
      this.textareaWrapper = module.querySelector('.js-question-form-textarea-wrapper')
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

      this.enableTextareaResizing(this.textareaWrapper)
      this.handleTextareaKeypress(this.textarea)
    }

    handleSubmit (event) {
      if (this.button.hasAttribute('aria-disabled')) {
        event.preventDefault()
        event.stopImmediatePropagation()
        return
      }

      const errors = []

      if (this.textarea.value.trim() === '') {
        errors.push(this.module.dataset.presenceErrorMessage)
      }

      this.replaceErrors(errors)

      const maxlength = parseInt(this.module.dataset.maxlength, 10)
      const exceedsMaxLength = this.textarea.value.length > maxlength

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
      this.resetTextarea()
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
      this.resetTextarea()
      this.enableControls()
    }

    disableControls () {
      this.textarea.readOnly = true
      this.toggleDisabledSettings(true)
    }

    enableControls () {
      this.textarea.readOnly = false
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

    resetTextarea () {
      this.textarea.value = ''
      this.textareaWrapper.dataset.replicatedValue = ''

      // Trigger keyup event so the character-count component resets and clears the count hint
      this.textarea.dispatchEvent(new Event('keyup'))
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
        this.attachTextareaDescriptions(this.errorsWrapper.id)
        this.textarea.focus()
      } else {
        this.resetTextareaDescriptions()
      }
    }

    attachTextareaDescriptions () {
      const ids = [this.module.dataset.hintId, ...arguments].join(' ')
      this.textarea.setAttribute('aria-describedby', ids)
    }

    resetTextareaDescriptions () {
      this.textarea.setAttribute('aria-describedby', this.module.dataset.hintId)
    }

    toggleErrorStyles (hasErrors) {
      if (hasErrors) {
        this.textarea.classList.add('app-c-question-form__textarea--error')
        this.formGroup.classList.add('app-c-question-form__form-group--error')
      } else {
        this.textarea.classList.remove('app-c-question-form__textarea--error')
        this.formGroup.classList.remove('app-c-question-form__form-group--error')
      }
    }

    enableTextareaResizing (textareaWrapper) {
      this.textarea.addEventListener('input', () => {
        textareaWrapper.dataset.replicatedValue = this.textarea.value
      })
    }

    handleTextareaKeypress (textarea) {
      textarea.addEventListener('keydown', e => {
        // Submit form on enter; add newline on enter + shift key
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          // The following approach to form submission was chosen over this.form.requestSubmit()
          // as requestSubmit() isn't supported in our grade C browsers
          window.GOVUK.triggerEvent(this.form, 'submit')
        }
      })
    }
  }

  Modules.QuestionForm = QuestionForm
})(window.GOVUK.Modules)

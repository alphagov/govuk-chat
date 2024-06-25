window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class AnswerFeedbackForm {
    constructor (module) {
      this.module = module
      this.buttonGroup = this.module.querySelector('.js-button-group')
      this.hideButton = this.module.querySelector('.js-hide-control')
      this.feedbackSubmittedDiv = this.module.querySelector('.js-feedback-submitted')
    }

    init () {
      this.module.addEventListener('submit', e => this.handleSubmit(e))
    }

    handleSubmit (event) {
      event.preventDefault()

      this.buttonGroup.hidden = true
      this.hideButton.addEventListener('click', e => this.hideComponent(e))
      this.feedbackSubmittedDiv.hidden = false

      try {
        const formData = new FormData(this.module)
        formData.append(event.submitter.name, event.submitter.value)
        fetch(this.module.action, {
          method: 'POST',
          body: formData,
          headers: {
            Accept: 'application/json'
          }
        })
      } catch (error) {
        console.error(error)
        this.module.submit()
      }
    }

    hideComponent (event) {
      event.preventDefault()
      this.module.hidden = true
    }
  }

  Modules.AnswerFeedbackForm = AnswerFeedbackForm
})(window.GOVUK.Modules)

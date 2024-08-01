window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class AnswerFeedback {
    constructor (module) {
      this.module = module
      this.form = this.module.querySelector('.js-form')
      this.hideButton = this.module.querySelector('.js-hide-control')
      this.feedbackSubmittedDiv = this.module.querySelector('.js-feedback-submitted')
    }

    init () {
      this.form.addEventListener('submit', e => this.handleSubmit(e))
    }

    handleSubmit (event) {
      event.preventDefault()

      this.form.hidden = true
      this.hideButton.addEventListener('click', e => this.hideComponent(e))
      this.feedbackSubmittedDiv.hidden = false
      this.feedbackSubmittedDiv.focus()

      try {
        const formData = new FormData(this.form)
        formData.append(event.submitter.name, event.submitter.value)
        fetch(this.form.action, {
          method: 'POST',
          body: formData,
          headers: {
            Accept: 'application/json'
          }
        })
      } catch (error) {
        console.error(error)
        this.form.submit()
      }
    }

    hideComponent (event) {
      event.preventDefault()
      this.module.hidden = true
    }
  }

  Modules.AnswerFeedback = AnswerFeedback
})(window.GOVUK.Modules)

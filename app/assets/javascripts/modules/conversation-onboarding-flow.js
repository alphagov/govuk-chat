window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ConversationOnboardingFlow {
    constructor (module) {
      this.module = module
      this.moduleWrapper = this.module.querySelector('.js-module-wrapper')
      this.conversationList = this.module.querySelector('.js-conversation-list')
      this.formContainer = this.module.querySelector('.js-form-container')
    }

    init () {
      this.moduleWrapper.addEventListener('onboarding-transition', e => this.handleOnboardingTransition(e))
    }

    handleOnboardingTransition (event) {
      const { path, fragment, conversationData, conversationAppendHtml, formHtml } = event.detail

      try {
        this.moduleWrapper.dispatchEvent(new Event('deinit'))

        history.replaceState(null, '', path)

        this.updateHtml(conversationData, conversationAppendHtml, formHtml)

        window.GOVUK.modules.start(this.module)

        if (fragment) {
          this.scrollIntoView(this.conversationList.querySelector(`#${fragment}`))
        }
      } catch (error) {
        console.error(error)
        this.redirect(path)
      }
    }

    updateHtml (conversationData, conversationAppendHtml, formHtml) {
      const dataset = this.moduleWrapper.dataset
      for (const key in dataset) {
        if (conversationData[key]) {
          dataset[key] = conversationData[key]
        } else {
          delete dataset[key]
        }
      }

      this.conversationList.insertAdjacentHTML('beforeend', conversationAppendHtml)
      this.formContainer.innerHTML = formHtml
    }

    scrollIntoView (element) {
      element.scrollIntoView()
    }

    redirect (url) {
      window.location.href = url
    }
  }
  Modules.ConversationOnboardingFlow = ConversationOnboardingFlow
})(window.GOVUK.Modules)

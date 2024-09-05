window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ConversationOnboardingFlow {
    constructor (module) {
      this.module = module
      this.conversationMessageRegion = this.module.querySelector('.js-conversation-message-region')
      this.conversationFromWidthRestrictor = this.module.querySelector('.js-conversation-form-width-restrictor')
      this.title = this.module.querySelector('.js-title')
    }

    init () {
      this.conversationMessageRegion.addEventListener('onboarding-transition', e => this.handleOnboardingTransition(e))
    }

    handleOnboardingTransition (event) {
      const { path, conversationData, conversationAppendHtml, formHtml, title } = event.detail

      try {
        this.conversationMessageRegion.dispatchEvent(new Event('deinit'))

        history.replaceState(null, '', path)
        this.updateBrowserTitle(title)

        this.updateHtml(conversationData, formHtml, title)

        window.GOVUK.modules.start(this.module)
        this.conversationMessageRegion.dispatchEvent(new CustomEvent('conversation-append', { detail: { html: conversationAppendHtml } }))
      } catch (error) {
        console.error(error)
        this.redirect(path)
      }
    }

    updateHtml (conversationData, formHtml, title) {
      const dataset = this.conversationMessageRegion.dataset
      for (const key in dataset) {
        if (conversationData[key]) {
          dataset[key] = conversationData[key]
        } else {
          delete dataset[key]
        }
      }

      this.conversationFromWidthRestrictor.innerHTML = formHtml
      this.title.textContent = title
    }

    scrollIntoView (element) {
      element.scrollIntoView()
    }

    redirect (url) {
      window.location.href = url
    }

    updateBrowserTitle (title) {
      let newTitle = title
      const splitTitle = document.title.split(' - ')

      if (splitTitle.length > 1) {
        newTitle += ` - ${splitTitle[splitTitle.length - 1]}`
      }

      document.title = newTitle
    }
  }
  Modules.ConversationOnboardingFlow = ConversationOnboardingFlow
})(window.GOVUK.Modules)

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class ConversationOnboardingFlow {
    constructor (module) {
      this.module = module
      this.moduleWrapper = this.module.querySelector('.js-module-wrapper')
      this.conversationList = this.module.querySelector('.js-conversation-list')
      this.formContainer = this.module.querySelector('.js-form-container')
      this.title = this.module.querySelector('.js-title')
    }

    init () {
      this.moduleWrapper.addEventListener('onboarding-transition', e => this.handleOnboardingTransition(e))
    }

    handleOnboardingTransition (event) {
      const { path, fragment, conversationData, conversationAppendHtml, formHtml, title } = event.detail

      try {
        this.moduleWrapper.dispatchEvent(new Event('deinit'))

        history.replaceState(null, '', path)
        this.updateBrowserTitle(title)

        this.updateHtml(conversationData, conversationAppendHtml, formHtml, title)

        window.GOVUK.modules.start(this.module)

        if (fragment) {
          this.scrollIntoView(this.conversationList.querySelector(`#${fragment}`))
        }
      } catch (error) {
        console.error(error)
        this.redirect(path)
      }
    }

    updateHtml (conversationData, conversationAppendHtml, formHtml, title) {
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

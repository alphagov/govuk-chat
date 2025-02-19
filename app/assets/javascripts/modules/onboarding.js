window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class Onboarding {
    constructor (module) {
      this.module = module
      this.form = this.module.querySelector('.js-onboarding-form')
      this.conversationFormRegion = this.module.querySelector('.js-conversation-form-region')
      this.messageLists = new Modules.ConversationMessageLists(this.module.querySelector('.js-conversation-message-lists'))
      this.eventListeners = []
    }

    init () {
      this.addEventListener(this.module, 'submit', e => this.handleSubmit(e))
      this.addEventListener(this.module, 'deinit', () => this.deinit())
      this.addEventListener(this.module, 'conversation-append', e => this.conversationAppend(e))

      if (this.messageLists.hasNewMessages()) {
        this.conversationFormRegion.classList.add('govuk-visually-hidden')
        this.messageLists.progressivelyDiscloseMessages().then(() => {
          this.conversationFormRegion.classList.add('app-conversation-layout__form-region--slide-in')
          this.conversationFormRegion.classList.remove('govuk-visually-hidden')
          this.messageLists.scrollToLastNewMessage()
        })
      }
    }

    async handleSubmit (event) {
      event.preventDefault()
      this.conversationFormRegion.classList.add('app-conversation-layout__form-region--slide-out')

      try {
        this.messageLists.moveNewMessagesToHistory()

        const formData = new FormData(this.form)
        formData.append(event.submitter.name, event.submitter.value)

        const response = await fetch(this.form.action, {
          method: this.form.method,
          body: formData,
          headers: {
            Accept: 'application/json'
          }
        })
        await this.handleFormResponse(response)
      } catch (error) {
        console.error(error)
        this.form.submit()
      }
    }

    async handleFormResponse (response) {
      if (response.status !== 200) {
        throw new Error(`Unexpected response status: ${response.status}`)
      }

      const responseJson = await response.json()

      const url = new URL(response.url)

      const eventDetail = {
        path: url.pathname, // just use pathname as URL could have fragment, unclear if supposed to: https://github.com/whatwg/fetch/issues/214
        conversationData: responseJson.conversation_data,
        conversationAppendHtml: responseJson.conversation_append_html,
        formHtml: responseJson.form_html,
        title: responseJson.title
      }

      const event = new CustomEvent('onboarding-transition', { detail: eventDetail })
      this.module.dispatchEvent(event)
    }

    deinit () {
      this.eventListeners.forEach(([element, event, handler]) => {
        element.removeEventListener(event, handler)
      })
    }

    async conversationAppend (event) {
      this.conversationFormRegion.classList.add('govuk-visually-hidden')
      this.conversationFormRegion.classList.remove('app-conversation-layout__form-region--slide-in')
      await this.messageLists.appendNewProgressivelyDisclosedMessages(event.detail.html)
      this.conversationFormRegion.classList.add('app-conversation-layout__form-region--slide-in')
      this.conversationFormRegion.classList.remove('app-conversation-layout__form-region--slide-out')
      this.conversationFormRegion.classList.remove('govuk-visually-hidden')
      this.messageLists.scrollToLastNewMessage()
    }

    addEventListener (element, event, handler) {
      element.addEventListener(event, handler)
      this.eventListeners.push([element, event, handler])
    }

    scrollIntoView (element) {
      element.scrollIntoView()
    }
  }
  Modules.Onboarding = Onboarding
})(window.GOVUK.Modules)

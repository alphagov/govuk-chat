window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  class Onboarding {
    constructor (module) {
      this.module = module
      this.form = this.module.querySelector('.js-onboarding-form')
      this.conversationList = this.module.querySelector('.js-conversation-list')
      this.eventListeners = []
    }

    init () {
      // if a user revisits or refreshes an ongoing onboarding process, scroll to the latest onboarding message
      if (this.conversationList.children.length > 0) {
        this.scrollIntoView(this.conversationList.lastElementChild)
      }

      this.addEventListener(this.module, 'submit', e => this.handleSubmit(e))
      this.addEventListener(this.module, 'deinit', () => this.deinit())
    }

    async handleSubmit (event) {
      event.preventDefault()

      try {
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
        fragment: responseJson.fragment, // ideally we'd get fragment from URL but browsers seem to strip it
        conversationData: responseJson.conversation_data,
        conversationAppendHtml: responseJson.conversation_append_html,
        formHtml: responseJson.form_html
      }
      const event = new CustomEvent('onboarding-transition', { detail: eventDetail })
      this.module.dispatchEvent(event)
    }

    deinit () {
      this.eventListeners.forEach(([element, event, handler]) => {
        element.removeEventListener(event, handler)
      })
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

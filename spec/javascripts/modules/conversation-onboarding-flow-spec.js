/* global asymmetricMatchers */

describe('ConversationOnboardingFlow module', () => {
  let moduleElement, module, moduleWrapper, conversationList, formContainer, titleElement

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <div class="js-module-wrapper" data-module="foo" data-other="bar">
        <h1 class="js-title"></h1>
        <ul class="js-conversation-list"></ul>
        <div class="js-form-container">
          <form class="js-onboarding-form" action="/chat/onboarding" method="post">
            <button>I understand</button>
          </form>
        </div>
      </div>
    `

    document.body.appendChild(moduleElement)
    moduleWrapper = moduleElement.querySelector('.js-module-wrapper')
    conversationList = moduleElement.querySelector('.js-conversation-list')
    formContainer = moduleElement.querySelector('.js-form-container')
    titleElement = moduleElement.querySelector('.js-title')

    module = new window.GOVUK.Modules.ConversationOnboardingFlow(moduleElement)
  })

  afterEach(() => {
    document.body.removeChild(moduleElement)
  })

  describe('init', () => {
    it('adds "onboarding-transition" event listeners', () => {
      const addEventListenerSpy = spyOn(moduleWrapper, 'addEventListener')
      module.init()

      expect(addEventListenerSpy).toHaveBeenCalled()
    })
  })

  describe('when receiving an onboarding-transition event', () => {
    let event, historyReplaceStateSpy, redirectSpy, originalBrowserTitle

    beforeEach(() => {
      event = {
        detail: {
          conversationAppendHtml: `
            <li id="i-understand">I understand</li>
            <li>Message</li>
          `,
          conversationData: { module: 'onboarding' },
          formHtml: '<form><button>Okay, start chatting</button></form>',
          fragment: 'i-understand',
          path: '/chat/onboarding/privacy',
          title: 'Title'
        }
      }

      historyReplaceStateSpy = spyOn(history, 'replaceState')

      module.init()

      redirectSpy = spyOn(module, 'redirect')
      originalBrowserTitle = document.title
      document.title = 'Page on - GOV.UK Chat'
    })

    afterEach(() => {
      document.title = originalBrowserTitle
    })

    it('dispatches "deinit" event on the module wrapper', () => {
      const onboardingEventSpy = spyOn(moduleWrapper, 'dispatchEvent')

      module.handleOnboardingTransition(event)

      const expectedEvent = jasmine.objectContaining({ type: 'deinit' })
      expect(onboardingEventSpy).toHaveBeenCalledWith(expectedEvent)
    })

    it('updates the most recent entry on the history stack', () => {
      module.handleOnboardingTransition(event)

      expect(historyReplaceStateSpy).toHaveBeenCalledWith(null, '', '/chat/onboarding/privacy')
    })

    it('replaces the data attributes on the wrapper', () => {
      moduleWrapper.dataset.module = 'onboarding'
      moduleWrapper.dataset.other = 'something'

      module.handleOnboardingTransition(event)

      expect(moduleWrapper.dataset.module).toEqual('onboarding')
      expect(moduleWrapper.dataset.other).toBeUndefined()
    })

    it('appends the new messages to the conversation list', () => {
      module.handleOnboardingTransition(event)

      expect(conversationList.children.length).toEqual(2)
      expect(conversationList.innerHTML).toContain('<li id="i-understand">I understand</li>')
      expect(conversationList.innerHTML).toContain('<li>Message</li>')
    })

    it('replaces the form', () => {
      module.handleOnboardingTransition(event)

      expect(formContainer.innerHTML).toContain(event.detail.formHtml)
    })

    it('updates the page title', () => {
      module.handleOnboardingTransition(event)

      expect(titleElement.textContent).toEqual(event.detail.title)
    })

    it('updates the browser title', () => {
      module.handleOnboardingTransition(event)

      expect(document.title).toEqual(`${event.detail.title} - GOV.UK Chat`)
    })

    it('initialises GOV.UK modules within the root element of this module', () => {
      const modulesStartSpy = spyOn(window.GOVUK.modules, 'start')

      module.handleOnboardingTransition(event)

      expect(modulesStartSpy).toHaveBeenCalledWith(moduleElement)
    })

    it('scrolls the fragment into view', () => {
      const scrollIntoViewSpy = spyOn(module, 'scrollIntoView')

      module.handleOnboardingTransition(event)

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(asymmetricMatchers.matchElementBySelector('#i-understand'))
    })

    describe('and an error occurs', () => {
      it('logs the error and redirects', () => {
        const consoleErrorSpy = spyOn(console, 'error')

        // A fragment that references an id that doesn't exist will cause an error
        event.detail.fragment = 'invalid-fragment'

        module.handleOnboardingTransition(event)

        expect(consoleErrorSpy).toHaveBeenCalled()
        expect(redirectSpy).toHaveBeenCalledWith('/chat/onboarding/privacy')
      })
    })
  })
})

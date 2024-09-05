describe('ConversationOnboardingFlow module', () => {
  let moduleElement, module, conversationMessageRegion, conversationFormWidthRestrictor, titleElement

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <div class="js-conversation-message-region" data-module="foo" data-other="bar">
        <h1 class="js-title"></h1>
        <div class="js-conversation-form-width-restrictor">
          <form class="js-onboarding-form" action="/chat/onboarding" method="post">
            <button>I understand</button>
          </form>
        </div>
      </div>
    `

    document.body.appendChild(moduleElement)
    conversationMessageRegion = moduleElement.querySelector('.js-conversation-message-region')
    conversationFormWidthRestrictor = moduleElement.querySelector('.js-conversation-form-width-restrictor')
    titleElement = moduleElement.querySelector('.js-title')

    module = new window.GOVUK.Modules.ConversationOnboardingFlow(moduleElement)
  })

  afterEach(() => {
    document.body.removeChild(moduleElement)
  })

  describe('init', () => {
    it('adds "onboarding-transition" event listeners', () => {
      const addEventListenerSpy = spyOn(conversationMessageRegion, 'addEventListener')
      module.init()

      expect(addEventListenerSpy).toHaveBeenCalled()
    })
  })

  describe('when receiving an onboarding-transition event', () => {
    let event, historyReplaceStateSpy, redirectSpy, originalBrowserTitle

    beforeEach(() => {
      event = {
        detail: {
          conversationAppendHtml: '<li>Message</li>',
          conversationData: { module: 'onboarding' },
          formHtml: '<form><button>Okay, start chatting</button></form>',
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
      const onboardingEventSpy = spyOn(conversationMessageRegion, 'dispatchEvent')

      module.handleOnboardingTransition(event)

      const expectedEvent = jasmine.objectContaining({ type: 'deinit' })
      expect(onboardingEventSpy).toHaveBeenCalledWith(expectedEvent)
    })

    it('updates the most recent entry on the history stack', () => {
      module.handleOnboardingTransition(event)

      expect(historyReplaceStateSpy).toHaveBeenCalledWith(null, '', '/chat/onboarding/privacy')
    })

    it('replaces the data attributes on the wrapper', () => {
      conversationMessageRegion.dataset.module = 'onboarding'
      conversationMessageRegion.dataset.other = 'something'

      module.handleOnboardingTransition(event)

      expect(conversationMessageRegion.dataset.module).toEqual('onboarding')
      expect(conversationMessageRegion.dataset.other).toBeUndefined()
    })

    it('fires an event to the module with the details of the conversation HTML to append', () => {
      const conversationMessageRegionEventSpy = spyOn(conversationMessageRegion, 'dispatchEvent')
      module.handleOnboardingTransition(event)

      const expectedEvent = jasmine.objectContaining({
        type: 'conversation-append',
        detail: { html: event.detail.conversationAppendHtml }
      })
      expect(conversationMessageRegionEventSpy).toHaveBeenCalledWith(expectedEvent)
    })

    it('replaces the form', () => {
      module.handleOnboardingTransition(event)

      expect(conversationFormWidthRestrictor.innerHTML).toContain(event.detail.formHtml)
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

    describe('and an error occurs', () => {
      it('logs the error and redirects', () => {
        const consoleErrorSpy = spyOn(console, 'error')
        historyReplaceStateSpy.and.throwError()

        module.handleOnboardingTransition(event)

        expect(consoleErrorSpy).toHaveBeenCalled()
        expect(redirectSpy).toHaveBeenCalledWith('/chat/onboarding/privacy')
      })
    })
  })
})

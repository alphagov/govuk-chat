/* global asymmetricMatchers */

describe('Onboarding module', () => {
  let moduleElement, module, conversationList, form

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <div class="js-module-wrapper">
        <ul class="js-conversation-list"></ul>
        <div class="js-form-container">
          <form class="js-onboarding-form" action="/chat/onboarding">
            <button>I understand</button>
          </form>
        </div>
      </div>
    `

    document.body.appendChild(moduleElement)
    conversationList = moduleElement.querySelector('.js-conversation-list')
    form = moduleElement.querySelector('.js-onboarding-form')

    module = new window.GOVUK.Modules.Onboarding(moduleElement)
  })

  afterEach(() => {
    document.body.removeChild(moduleElement)
  })

  describe('init', () => {
    it('executes handleSubmit on form submit', () => {
      const handleSubmitSpy = spyOn(module, 'handleSubmit')

      module.init()
      moduleElement.dispatchEvent(new Event('submit'))

      expect(handleSubmitSpy).toHaveBeenCalled()
    })

    it('executes deinit on the deinit event', () => {
      const deinitSpy = spyOn(module, 'deinit')

      module.init()
      moduleElement.dispatchEvent(new Event('deinit'))

      expect(deinitSpy).toHaveBeenCalled()
    })

    it('scrolls the most recent onboarding message into view', () => {
      conversationList.innerHTML = '<li class="js-conversation-message" id="onboarding-message"></li>'

      // declare a new instance of module so it can take the above HTML into account when it's instantiated
      module = new window.GOVUK.Modules.Onboarding(moduleElement)
      const scrollIntoViewSpy = spyOn(module, 'scrollIntoView')

      module.init()

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(asymmetricMatchers.matchElementBySelector('#onboarding-message'))
    })
  })

  describe('deinit', () => {
    it('removes the attached event listeners', () => {
      const removeEventListenerSpy = spyOn(moduleElement, 'removeEventListener')

      module.init() // init() adds the event listeners
      module.deinit()

      expect(removeEventListenerSpy).toHaveBeenCalledTimes(2)
    })
  })

  describe('handle submit', () => {
    let event, fetchSpy

    beforeEach(() => {
      const responseJson = {
        conversation_append_html: '<p>Message</p>',
        conversation_data: { module: 'onboarding' },
        form_html: '<form></form>',
        fragment: 'i-understand',
        title: 'Title'
      }

      fetchSpy = spyOn(window, 'fetch')
      const response =
        new Response(JSON.stringify(responseJson),
          {
            status: 200
          })
      Object.defineProperty(response, 'url', { value: 'https://gov.uk/chat/conversation' })

      fetchSpy.and.resolveTo(response)

      event = new Event('submit')
      event.submitter = { name: 'more_information', value: 'true' }

      module.init()
    })

    it('prevents the event from performing default behaviour', async () => {
      const preventDefaultSpy = spyOn(event, 'preventDefault')

      await module.handleSubmit(event)

      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('submits a JSON fetch request to the action of the form', async () => {
      const handleFormResponseSpy = spyOn(module, 'handleFormResponse')

      const formData = new FormData()
      formData.append('more_information', 'true')
      await module.handleSubmit(event)

      expect(fetchSpy).toHaveBeenCalledWith(form.action, jasmine.objectContaining({
        method: form.method,
        body: formData,
        headers: {
          Accept: 'application/json'
        }
      }
      ))
      expect(handleFormResponseSpy).toHaveBeenCalled()
    })

    describe('when receiving a successful response', () => {
      it('dispatches an "onboarding-transition" event on the module with response details', async () => {
        const eventSpy = spyOn(moduleElement, 'dispatchEvent')

        await module.handleSubmit(event)

        const expectedEvent = jasmine.objectContaining({
          type: 'onboarding-transition',
          detail: {
            path: '/chat/conversation',
            fragment: 'i-understand',
            conversationAppendHtml: '<p>Message</p>',
            conversationData: { module: 'onboarding' },
            formHtml: '<form></form>',
            title: 'Title'
          }
        })
        expect(eventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })

    describe('when receiving an unexpected status code', () => {
      beforeEach(() => {
        fetchSpy.and.resolveTo(
          new Response('',
            {
              status: 500
            })
        )
      })

      it('logs the error and submits the form', async () => {
        const consoleErrorSpy = spyOn(console, 'error')
        const formSubmitSpy = spyOn(module.form, 'submit')

        await module.handleSubmit(event)

        expect(consoleErrorSpy).toHaveBeenCalledWith(Error('Unexpected response status: 500'))
        expect(formSubmitSpy).toHaveBeenCalled()
      })
    })
  })
})

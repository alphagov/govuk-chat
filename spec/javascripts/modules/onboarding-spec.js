describe('Onboarding module', () => {
  let moduleElement, module, form
  const longWaitForProgressiveDisclosure = 60000

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <div class="js-module-wrapper">
        <div class="js-conversation-message-lists">
          <ul class="js-message-history-list"></ul>
          <div class="js-new-messages-region">
            <ul class="js-new-messages-list"></ul>
          </div>
        </div>
        <div class="js-form-container">
          <form class="js-onboarding-form" action="/chat/onboarding">
            <button>I understand</button>
          </form>
        </div>
      </div>
    `

    document.body.appendChild(moduleElement)
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

    it('executes conversationAppend on the conversation-append event', () => {
      const conversationAppendSpy = spyOn(module, 'conversationAppend')

      module.init()
      moduleElement.dispatchEvent(new Event('conversation-append'))

      expect(conversationAppendSpy).toHaveBeenCalled()
    })

    it('delegates to messageLists to progressively disclose messages', () => {
      const progressivelyDiscloseMessagesSpy = spyOn(module.messageLists, 'progressivelyDiscloseMessages').and.resolveTo()

      module.init()

      expect(progressivelyDiscloseMessagesSpy).toHaveBeenCalled()
    })

    it('hides the form prior to disclosing messages and then shows it', done => {
      jasmine.clock().install()

      // add some messages to disclose
      const newMessagesList = moduleElement.querySelector('.js-new-messages-list')
      newMessagesList.innerHTML = `
        <li class="js-conversation-message">To show</li>
        <li class="js-conversation-message">To disclose</li>
      `
      module.init()

      // using toHaveClass matcher was triggering a "stale element" error so using other matcher
      expect(form.classList).toContain('govuk-visually-hidden')

      jasmine.clock().tick(longWaitForProgressiveDisclosure)
      jasmine.clock().uninstall()

      // timeout to ensure promise callbacks are executed
      window.setTimeout(() => {
        expect(form.classList).not.toContain('govuk-visually-hidden')
        done()
      }, 0)
    })
  })

  describe('deinit', () => {
    it('removes the attached event listeners', () => {
      const removeEventListenerSpy = spyOn(moduleElement, 'removeEventListener')

      module.init() // init() adds the event listeners
      module.deinit()

      expect(removeEventListenerSpy).toHaveBeenCalledTimes(3)
    })
  })

  describe('handle submit', () => {
    let event, fetchSpy

    beforeEach(() => {
      const responseJson = {
        conversation_append_html: '<p>Message</p>',
        conversation_data: { module: 'onboarding' },
        form_html: '<form></form>',
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

    it('delegates to messagesList to move new messages to history', async () => {
      const moveNewMessagesToHistorySpy = spyOn(module.messageLists, 'moveNewMessagesToHistory')
      await module.handleSubmit(event)
      expect(moveNewMessagesToHistorySpy).toHaveBeenCalled()
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

  describe('handle conversationAppend event', () => {
    let event

    beforeEach(() => {
      event = new CustomEvent(
        'conversation-append',
        {
          detail: {
            html: `
              <li class="js-conversation-message">To show</li>
              <li class="js-conversation-message">To disclose</li>
            `
          }
        }
      )
    })

    it('delegates to messageLists to append new progressively disclosed messages', () => {
      module.init()

      const appendNewProgressivelyDisclosedMessagesSpy = spyOn(
        module.messageLists,
        'appendNewProgressivelyDisclosedMessages'
      )

      moduleElement.dispatchEvent(event)

      expect(appendNewProgressivelyDisclosedMessagesSpy).toHaveBeenCalled()
    })

    it('hides the form prior to disclosing messages and then shows it after', done => {
      jasmine.clock().install()

      module.init()

      moduleElement.dispatchEvent(event)

      expect(form).toHaveClass('govuk-visually-hidden')

      jasmine.clock().tick(longWaitForProgressiveDisclosure)
      jasmine.clock().uninstall()

      // timeout to ensure promise callbacks are executed
      window.setTimeout(() => {
        expect(form).not.toHaveClass('govuk-visually-hidden')
        done()
      }, 0)
    })
  })
})

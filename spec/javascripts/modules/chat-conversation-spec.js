describe('ChatConversation module', () => {
  let moduleElement, module, conversationList

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <ul class="js-conversation-list"></ul>
      <form class="js-conversation-form" action="/conversation">
        <input type="text" name="question" value="How can I setup a new business?">
      </form>
    `

    document.body.appendChild(moduleElement)
    conversationList = moduleElement.querySelector('.js-conversation-list')

    module = new window.GOVUK.Modules.ChatConversation(moduleElement)
    module.init()
  })

  afterEach(() => {
    document.body.removeChild(moduleElement)
  })

  describe('handleFormSubmission', () => {
    let redirectToAnswerUrlSpy, fetchSpy

    beforeEach(() => {
      const responseJson = {
        question_html: '<li>How can I setup a new business?</li>',
        answer_url: '/answer',
        error_messages: []
      }

      fetchSpy = spyOn(window, 'fetch')
      fetchSpy.and.resolveTo(
        new Response(JSON.stringify(responseJson), { status: 201 })
      )

      redirectToAnswerUrlSpy = spyOn(module, 'redirectToAnswerUrl')
    })

    it('prevents the event from performing default behaviour', async () => {
      const event = new Event('submit')
      const preventDefaultSpy = spyOn(event, 'preventDefault')

      await module.handleFormSubmission(event)

      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('submits a JSON fetch request to the action of the form', async () => {
      const form = moduleElement.querySelector('.js-conversation-form')

      await module.handleFormSubmission(new Event('submit'))

      const formData = new FormData()
      formData.append('question', 'How can I setup a new business?')

      expect(fetchSpy).toHaveBeenCalledWith(form.action, jasmine.objectContaining({
        method: 'POST',
        body: formData,
        headers: {
          Accept: 'application/json'
        }
      }))
    })

    it('dispatches a question-pending event on the form element', async () => {
      const formEventSpy = spyOn(module.form, 'dispatchEvent')

      await module.handleFormSubmission(new Event('submit'))

      const expectedEvent = jasmine.objectContaining({ type: 'question-pending' })
      expect(formEventSpy).toHaveBeenCalledWith(expectedEvent)
    })

    describe('when receiving a successful question response', () => {
      it('redirects to the answer url', async () => {
        await module.handleFormSubmission(new Event('submit'))

        expect(redirectToAnswerUrlSpy).toHaveBeenCalledWith('/answer')
      })

      it('appends the question HTML to the conversation list', async () => {
        await module.handleFormSubmission(new Event('submit'))

        expect(conversationList.children.length).toEqual(1)
        expect(conversationList.textContent).toContain('How can I setup a new business?')
      })

      it('dispatches a "question-accepted" event on the form element', async () => {
        const formEventSpy = spyOn(module.form, 'dispatchEvent')

        await module.handleFormSubmission(new Event('submit'))

        const expectedEvent = jasmine.objectContaining({ type: 'question-accepted' })
        expect(formEventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })

    describe('when receiving an unproccessible entity response', () => {
      it('dispatches a "question-rejected" event on the form element', async () => {
        const responseJson = {
          error_messages: ['form error']
        }

        fetchSpy.and.resolveTo(
          new Response(JSON.stringify(responseJson), { status: 422 })
        )

        const formEventSpy = spyOn(module.form, 'dispatchEvent')

        await module.handleFormSubmission(new Event('submit'))

        const expectedEvent = jasmine.objectContaining({ type: 'question-rejected', detail: { errorMessages: ['form error'] } })
        expect(formEventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })

    describe('when receiving an unexpected status code', () => {
      it('logs the error and submits the form', async () => {
        fetchSpy.and.resolveTo(new Response('', { status: 500 }))

        const consoleErrorSpy = spyOn(console, 'error')
        const formSubmitSpy = spyOn(module.form, 'submit')

        await module.handleFormSubmission(new Event('submit'))

        expect(consoleErrorSpy).toHaveBeenCalledWith(Error('Unexpected response status: 500'))
        expect(formSubmitSpy).toHaveBeenCalled()
      })
    })

    describe('when receiving an invalid json response', () => {
      it('logs the error and submits the form', async () => {
        fetchSpy.and.resolveTo(new Response('', { status: 201 }))

        const consoleErrorSpy = spyOn(console, 'error')
        const formSubmitSpy = spyOn(module.form, 'submit')

        await module.handleFormSubmission(new Event('submit'))

        expect(consoleErrorSpy).toHaveBeenCalled()
        expect(formSubmitSpy).toHaveBeenCalled()
      })
    })
  })
})

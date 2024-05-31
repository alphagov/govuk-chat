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
    let checkAnswerSpy, fetchSpy

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

      checkAnswerSpy = spyOn(module, 'checkAnswer')
      jasmine.clock().install()
    })

    afterEach(() => {
      jasmine.clock().uninstall()
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

      it('starts the process to load an answer', async () => {
        await module.handleFormSubmission(new Event('submit'))

        jasmine.clock().tick(module.ANSWER_INTERVAL)

        expect(checkAnswerSpy).toHaveBeenCalled()
        expect(module.pendingAnswerUrl).toEqual('/answer')
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

  describe('checkAnswer', () => {
    let redirectSpy

    beforeEach(() => {
      redirectSpy = spyOn(module, 'redirect')
    })

    it("doesn't make a fetch request when 'pendingAnswerUrl' is null", async () => {
      const fetchSpy = spyOn(window, 'fetch')
      module.pendingAnswerUrl = null

      await module.checkAnswer()

      expect(fetchSpy).not.toHaveBeenCalled()
    })

    describe('when the answer is ready', () => {
      beforeEach(() => {
        module.pendingAnswerUrl = '/answer'

        const responseJson = {
          answer_html: '<li>Your answer</li>'
        }

        spyOn(window, 'fetch').and.resolveTo(
          new Response(JSON.stringify(responseJson), {
            status: 200
          })
        )
      })

      it('appends the answer to the conversation list', async () => {
        await module.checkAnswer()

        expect(conversationList.children.length).toEqual(1)
        expect(conversationList.textContent).toContain('Your answer')
      })

      it('resets the "pendingAnswerUrl" value', async () => {
        await module.checkAnswer()

        expect(module.pendingAnswerUrl).toBeNull()
      })

      it('dispatches an "answer-received" event to the form', async () => {
        const formEventSpy = spyOn(module.form, 'dispatchEvent')

        await module.checkAnswer()

        const expectedEvent = jasmine.objectContaining({ type: 'answer-received' })
        expect(formEventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })

    describe('when the answer is pending', () => {
      it('attempts to load the answer after a delay', async () => {
        jasmine.clock().install()

        module.pendingAnswerUrl = '/answer'

        const pendingResponse = new Response('', { status: 202 })
        const successResponse = new Response(JSON.stringify({ answer_html: '<li>Answer</li>' }), { status: 200 })

        const fetchSpy = spyOn(window, 'fetch').and.returnValues(
          Promise.resolve(pendingResponse),
          Promise.resolve(successResponse)
        )
        await module.checkAnswer()
        jasmine.clock().tick(module.ANSWER_INTERVAL)

        expect(fetchSpy).toHaveBeenCalledTimes(2)

        jasmine.clock().uninstall()
      })
    })

    describe('when receiving an unexpected response from the answer endpoint', () => {
      it('redirects to the answer url and logs an error', async () => {
        const answerUrl = '/answer'
        module.pendingAnswerUrl = answerUrl

        spyOn(window, 'fetch').and.resolveTo(new Response('error', { status: 500 }))

        await module.checkAnswer()

        expect(redirectSpy).toHaveBeenCalledWith(answerUrl)
      })
    })
  })
})

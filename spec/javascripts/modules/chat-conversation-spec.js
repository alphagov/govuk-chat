describe('ChatConversation module', () => {
  let moduleElement, module, conversationList, form, formContainer

  const matchElementBySelector = (selector) => {
    return {
      asymmetricMatch: (element) => element.matches(selector),
      jasmineToString: () => `<matchElementBySelector:${selector}>`
    }
  }

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <ul class="js-conversation-list"></ul>
      <div class="js-form-container">
        <form class="js-conversation-form" action="/conversation">
          <input type="text" name="question" value="How can I setup a new business?">
        </form>
      </div>
    `

    document.body.appendChild(moduleElement)
    conversationList = moduleElement.querySelector('.js-conversation-list')
    form = moduleElement.querySelector('.js-conversation-form')
    formContainer = moduleElement.querySelector('.js-form-container')

    module = new window.GOVUK.Modules.ChatConversation(moduleElement)
  })

  afterEach(() => {
    document.body.removeChild(moduleElement)
  })

  describe('init', () => {
    it('adds an event listener for handleFormSubmission for submit events', () => {
      const handleFormSubmissionSpy = spyOn(module, 'handleFormSubmission')

      module.init()
      formContainer.dispatchEvent(new Event('submit'))

      expect(handleFormSubmissionSpy).toHaveBeenCalled()
    })

    describe('when there is a pendingAnswerUrl and the form component is initialised', () => {
      beforeEach(() => {
        module.pendingAnswerUrl = '/answer'
        form.dataset.conversationFormModuleStarted = 'true'
      })

      it('starts checking for an answer and dispatches an event so the form is in the correct state', () => {
        const checkAnswerSpy = spyOn(module, 'checkAnswer')
        const formEventSpy = spyOn(form, 'dispatchEvent')

        module.init()

        expect(checkAnswerSpy).toHaveBeenCalled()
        const expectedEvent = jasmine.objectContaining({ type: 'question-accepted' })
        expect(formEventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })

    describe('when there is a pendingAnswerUrl and the form component is not initialised', () => {
      beforeEach(() => {
        module.pendingAnswerUrl = '/answer'
      })

      it('starts checking for answer and changing form state once the form is initialised', () => {
        const checkAnswerSpy = spyOn(module, 'checkAnswer')
        const formEventSpy = spyOn(form, 'dispatchEvent').and.callThrough()

        module.init()

        expect(checkAnswerSpy).not.toHaveBeenCalled()
        expect(formEventSpy).not.toHaveBeenCalled()

        form.dispatchEvent(new Event('init'))

        expect(checkAnswerSpy).toHaveBeenCalled()
        const expectedEvent = jasmine.objectContaining({ type: 'question-accepted' })
        expect(formEventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })
  })

  describe('handleFormSubmission', () => {
    let checkAnswerSpy, fetchSpy

    beforeEach(() => {
      module.init()

      const responseJson = {
        question_html: '<li id="question_123">How can I setup a new business?</li>',
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

      it('scrolls the question into view', async () => {
        const scrollToMessageSpy = spyOn(module, 'scrollToMessage')

        await module.handleFormSubmission(new Event('submit'))

        expect(scrollToMessageSpy).toHaveBeenCalledWith(matchElementBySelector('#question_123'))
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
      module.init()
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
          answer_html: '<li id="answer_123">Your answer</li>'
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

      it('scrolls the answer into view', async () => {
        const scrollToMessageSpy = spyOn(module, 'scrollToMessage')

        await module.checkAnswer()

        expect(scrollToMessageSpy).toHaveBeenCalledWith(matchElementBySelector('#answer_123'))
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

      it('starts any nested modules', async () => {
        const startSpy = spyOn(window.GOVUK.modules, 'start')

        await module.checkAnswer()

        expect(startSpy).toHaveBeenCalledWith(conversationList)
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

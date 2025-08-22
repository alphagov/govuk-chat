describe('ChatConversation module', () => {
  let conversationFormRegion, moduleElement, module, formContainer, form
  const longWaitForProgressiveDisclosure = 60000

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <div class="js-conversation-message-lists">
        <ul class="js-conversation-message-history-list"></ul>
        <div class="js-new-conversation-messages-container">
          <ul class="js-new-conversation-messages-list"></ul>
        </div>
        <template class="js-loading-question"><li>Loading</li></template>
        <template class="js-loading-answer"><li>Loading</li></template>
      </div>
      <div class="js-conversation-form-region">
        <div class="js-question-form-container">
          <form action="/conversation" class="js-question-form">
            <textarea name="question">How can I setup a new business?</textarea>
            <button class="js-question-form-button">Send</button>
          </form>
        </div>
      </div>
    `

    document.body.appendChild(moduleElement)
    conversationFormRegion = moduleElement.querySelector('.js-conversation-form-region')
    formContainer = moduleElement.querySelector('.js-question-form-container')
    form = moduleElement.querySelector('.js-question-form')

    module = new window.GOVUK.Modules.ChatConversation(moduleElement)
  })

  afterEach(() => {
    document.body.removeChild(moduleElement)
  })

  describe('init', () => {
    it('adds an event listener for handleFormSubmission for form component submit events', () => {
      const handleFormSubmissionSpy = spyOn(module, 'handleFormSubmission')

      module.init()
      formContainer.dispatchEvent(new Event('submit'))

      expect(handleFormSubmissionSpy).toHaveBeenCalled()
    })

    describe('when initialised with existing new messages for the first time', () => {
      beforeEach(() => {
        window.GOVUK.deleteCookie('govuk_chat_onboarding_complete')

        const newMessagesList = moduleElement.querySelector('.js-new-conversation-messages-list')
        newMessagesList.innerHTML = `
          <li class="js-conversation-message">Message 1</li>
          <li class="js-conversation-message">Message 2</li>
        `
      })

      it('delegates to messageLists to progressively disclose messages', () => {
        const progressivelyDiscloseMessagesSpy = spyOn(module.messageLists, 'progressivelyDiscloseMessages').and.resolveTo()

        module.init()

        expect(progressivelyDiscloseMessagesSpy).toHaveBeenCalled()
      })

      it('hides the form component prior to disclosing messages and then shows it', done => {
        jasmine.clock().install()

        module.init()

        // using toHaveClass matcher was triggering a "stale element" error so using other matcher
        expect(conversationFormRegion.classList).toContain('govuk-visually-hidden')

        jasmine.clock().tick(longWaitForProgressiveDisclosure)
        jasmine.clock().uninstall()

        // timeout to ensure promise callbacks are executed
        window.setTimeout(() => {
          expect(conversationFormRegion.classList).not.toContain('govuk-visually-hidden')
          expect(conversationFormRegion.classList).toContain('app-conversation-layout__form-region--slide-in')
          done()
        }, 0)
      })
    })

    describe('when initialised with existing new messages after the govuk_onboarding_complete cookie has been set', () => {
      beforeEach(() => {
        window.GOVUK.cookie('govuk_chat_onboarding_complete', 'true')

        const newMessagesList = moduleElement.querySelector('.js-new-conversation-messages-list')
        newMessagesList.innerHTML = `
          <li class="js-conversation-message">Message 1</li>
          <li class="js-conversation-message">Message 2</li>
        `
      })

      afterEach(() => {
        window.GOVUK.deleteCookie('govuk_chat_onboarding_complete')
      })

      it('does not progressively disclose messages', () => {
        const progressivelyDiscloseMessagesSpy = spyOn(module.messageLists, 'progressivelyDiscloseMessages').and.resolveTo()

        module.init()

        expect(progressivelyDiscloseMessagesSpy).not.toHaveBeenCalled()
      })

      it('does not hide the form component', () => {
        module.init()

        expect(conversationFormRegion.classList).not.toContain('govuk-visually-hidden')
      })
    })

    describe('when initialised without existing new messages', () => {
      it('delegates to messageLists to scroll to last message', () => {
        const scrollToLastMessageInHistorySpy = spyOn(module.messageLists, 'scrollToLastMessageInHistory')

        module.init()

        expect(scrollToLastMessageInHistorySpy).toHaveBeenCalled()
      })
    })

    describe('when there is a pendingAnswerUrl and the form component is initialised', () => {
      let checkAnswerSpy

      beforeEach(() => {
        module.pendingAnswerUrl = '/answer'
        formContainer.dataset.conversationFormModuleStarted = 'true'
        checkAnswerSpy = spyOn(module, 'checkAnswer')
      })

      it('delegates to messageLists to render an answer loading state', () => {
        const renderAnswerLoadingSpy = spyOn(module.messageLists, 'renderAnswerLoading')

        module.init()

        expect(renderAnswerLoadingSpy).toHaveBeenCalled()
      })

      it('starts checking for an answer and dispatches an event so the form is in the correct state', () => {
        const formContainerEventSpy = spyOn(formContainer, 'dispatchEvent')

        module.init()

        expect(checkAnswerSpy).toHaveBeenCalled()
        const expectedEvent = jasmine.objectContaining({ type: 'question-accepted' })
        expect(formContainerEventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })

    describe('when there is a pendingAnswerUrl and the form component is not initialised', () => {
      beforeEach(() => {
        module.pendingAnswerUrl = '/answer'
      })

      it('starts checking for answer and changing form state once the form component is initialised', () => {
        const checkAnswerSpy = spyOn(module, 'checkAnswer')
        const formContainerEventSpy = spyOn(formContainer, 'dispatchEvent').and.callThrough()

        module.init()

        expect(checkAnswerSpy).not.toHaveBeenCalled()
        expect(formContainerEventSpy).not.toHaveBeenCalled()

        formContainer.dispatchEvent(new Event('init'))

        expect(checkAnswerSpy).toHaveBeenCalled()
        const expectedEvent = jasmine.objectContaining({ type: 'question-accepted' })
        expect(formContainerEventSpy).toHaveBeenCalledWith(expectedEvent)
      })
    })
  })

  describe('handleFormSubmission', () => {
    let checkAnswerSpy, fetchSpy, successfulQuestionResponseJson

    beforeEach(() => {
      module.init()

      successfulQuestionResponseJson = {
        question_html: '<li id="question_123">How can I setup a new business?</li>',
        answer_url: '/answer',
        error_messages: []
      }

      fetchSpy = spyOn(window, 'fetch')
      fetchSpy.and.resolveTo(
        new Response(JSON.stringify(successfulQuestionResponseJson), { status: 201 })
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

    it('delegates to messageLists to move any new messages to history', async () => {
      const moveNewMessagesToHistorySpy = spyOn(module.messageLists, 'moveNewMessagesToHistory')
      const event = new Event('submit')

      await module.handleFormSubmission(event)

      expect(moveNewMessagesToHistorySpy).toHaveBeenCalled()
    })

    it('delegates to messageLists to render a loading question state', async () => {
      const renderQuestionLoadingSpy = spyOn(module.messageLists, 'renderQuestionLoading')
      const event = new Event('submit')

      await module.handleFormSubmission(event)

      expect(renderQuestionLoadingSpy).toHaveBeenCalled()
    })

    it('submits a JSON fetch request to the action of the form', async () => {
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

    it('dispatches a question-pending event on the form component element', async () => {
      const formEventSpy = spyOn(module.formContainer, 'dispatchEvent')

      await module.handleFormSubmission(new Event('submit'))

      const expectedEvent = jasmine.objectContaining({ type: 'question-pending' })
      expect(formEventSpy).toHaveBeenCalledWith(expectedEvent)
    })

    describe('when receiving a successful question response', () => {
      it('delegates to messageLists to render the question', async () => {
        const renderQuestionSpy = spyOn(module.messageLists, 'renderQuestion')
        await module.handleFormSubmission(new Event('submit'))

        expect(renderQuestionSpy).toHaveBeenCalledWith(successfulQuestionResponseJson.question_html)
      })

      it('delegates to messageLists to render loading an answer', async () => {
        const renderAnswerLoadingSpy = spyOn(module.messageLists, 'renderAnswerLoading')
        await module.handleFormSubmission(new Event('submit'))

        expect(renderAnswerLoadingSpy).toHaveBeenCalled()
      })

      it('dispatches a "question-accepted" event on the form component element', async () => {
        const formContainerEventSpy = spyOn(module.formContainer, 'dispatchEvent')

        await module.handleFormSubmission(new Event('submit'))

        const expectedEvent = jasmine.objectContaining({ type: 'question-accepted' })
        expect(formContainerEventSpy).toHaveBeenCalledWith(expectedEvent)
      })

      it('dispatches a "conversation-active" event on the module element', async () => {
        const moduleElementEventSpy = spyOn(moduleElement, 'dispatchEvent')

        await module.handleFormSubmission(new Event('submit'))

        const expectedEvent = jasmine.objectContaining({
          type: 'conversation-active',
          bubbles: true
        })
        expect(moduleElementEventSpy).toHaveBeenCalledWith(expectedEvent)
      })

      it('starts the process to load an answer', async () => {
        await module.handleFormSubmission(new Event('submit'))

        jasmine.clock().tick(module.ANSWER_INTERVAL)

        expect(checkAnswerSpy).toHaveBeenCalled()
        expect(module.pendingAnswerUrl).toEqual('/answer')
      })
    })

    describe('when receiving an unproccessible content response', () => {
      beforeEach(() => {
        const responseJson = {
          error_messages: ['form error']
        }

        fetchSpy.and.resolveTo(
          new Response(JSON.stringify(responseJson), { status: 422 })
        )
      })

      it('dispatches a "question-rejected" event on the form component element', async () => {
        const formContainerEventSpy = spyOn(module.formContainer, 'dispatchEvent')

        await module.handleFormSubmission(new Event('submit'))

        const expectedEvent = jasmine.objectContaining({ type: 'question-rejected', detail: { errorMessages: ['form error'] } })
        expect(formContainerEventSpy).toHaveBeenCalledWith(expectedEvent)
      })

      it('delegates to messageLists to reset question loading', async () => {
        const resetQuestionLoadingSpy = spyOn(module.messageLists, 'resetQuestionLoading')

        await module.handleFormSubmission(new Event('submit'))

        expect(resetQuestionLoadingSpy).toHaveBeenCalled()
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
      let answerHtml

      beforeEach(() => {
        module.pendingAnswerUrl = '/answer'

        answerHtml = '<li id="answer_123">your answer</li>'

        const responseJson = { answer_html: answerHtml }

        spyOn(window, 'fetch').and.resolveTo(
          new Response(JSON.stringify(responseJson), {
            status: 200
          })
        )
      })

      it('delegates to messageLists to render the answer', async () => {
        const renderAnswerSpy = spyOn(module.messageLists, 'renderAnswer')

        await module.checkAnswer()

        expect(renderAnswerSpy).toHaveBeenCalledWith(answerHtml)
      })

      it('resets the "pendingAnswerUrl" value', async () => {
        await module.checkAnswer()

        expect(module.pendingAnswerUrl).toBeNull()
      })

      it('dispatches an "answer-received" event to the form component', async () => {
        const formContainerEventSpy = spyOn(module.formContainer, 'dispatchEvent')

        await module.checkAnswer()

        const expectedEvent = jasmine.objectContaining({ type: 'answer-received' })
        expect(formContainerEventSpy).toHaveBeenCalledWith(expectedEvent)
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

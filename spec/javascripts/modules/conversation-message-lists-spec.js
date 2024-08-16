describe('ConversationMessageLists module', () => {
  let moduleElement, module, messageHistoryList, newMessagesList, scrollIntoViewSpy,
    progressiveDisclosureDelay, questionLoadingTimeout

  beforeEach(() => {
    moduleElement = document.createElement('div')
    moduleElement.innerHTML = `
      <ul class="js-message-history-list"></ul>
      <ul class="js-new-messages-list"></ul>
      <template class="js-loading-question">
        <li>Loading question</li>
      </template>
      <template class="js-loading-answer">
        <li>Loading answer</li>
      </template>
    `

    document.body.appendChild(moduleElement)
    messageHistoryList = moduleElement.querySelector('.js-message-history-list')
    newMessagesList = moduleElement.querySelector('.js-new-messages-list')

    module = new window.GOVUK.Modules.ConversationMessageLists(moduleElement)
    progressiveDisclosureDelay = module.PROGRESSIVE_DISCLOSURE_DELAY
    questionLoadingTimeout = module.QUESTION_LOADING_TIMEOUT

    scrollIntoViewSpy = spyOn(module, 'scrollIntoView')
  })

  afterEach(() => {
    document.body.removeChild(moduleElement)
  })

  describe('hasNewMessages', () => {
    it('returns true if there are elements matching the messages selector in the new messgaes list', () => {
      newMessagesList.innerHTML = '<li class="js-conversation-message">Message</li>'
      expect(module.hasNewMessages()).toBe(true)
    })

    it('returns false if there are no elements matching the messages selector in the new messgaes list', () => {
      newMessagesList.innerHTML = '<li>other selector</li>'
      expect(module.hasNewMessages()).toBe(false)
    })
  })

  describe('progressivelyDiscloseMessages', () => {
    beforeEach(() => { jasmine.clock().install() })
    afterEach(() => { jasmine.clock().uninstall() })

    describe('when there are new messages', () => {
      beforeEach(() => {
        newMessagesList.innerHTML = `
          <li class="js-conversation-message">Message</li>
          <li class="js-conversation-message">Message</li>
          <li class="js-conversation-message">Message</li>
        `
      })

      it('initially hides the messages after the first message', done => {
        const promise = module.progressivelyDiscloseMessages()
        const messages = newMessagesList.querySelectorAll('.js-conversation-message')
        expect(messages[0]).not.toHaveClass('govuk-visually-hidden')
        expect(messages[1]).toHaveClass('govuk-visually-hidden')
        expect(messages[2]).toHaveClass('govuk-visually-hidden')
        jasmine.clock().tick(progressiveDisclosureDelay * newMessagesList.children.length)
        promise.then(() => done())
      })

      it('initially scrolls to the first message', done => {
        const promise = module.progressivelyDiscloseMessages()
        const messages = newMessagesList.querySelectorAll('.js-conversation-message')
        expect(scrollIntoViewSpy).toHaveBeenCalledWith(messages[0])
        jasmine.clock().tick(progressiveDisclosureDelay * newMessagesList.children.length)
        promise.then(() => done())
      })

      it('unhides, fades in and scrolls to each hidden message after a delay', done => {
        const promise = module.progressivelyDiscloseMessages()
        const messages = newMessagesList.querySelectorAll('.js-conversation-message')

        jasmine.clock().tick(progressiveDisclosureDelay)
        expect(messages[1]).not.toHaveClass('govuk-visually-hidden')
        expect(messages[1]).toHaveClass('app-c-conversation-message--fade-in')
        expect(messages[2]).toHaveClass('govuk-visually-hidden')
        expect(messages[2]).not.toHaveClass('app-c-conversation-message--fade-in')
        expect(scrollIntoViewSpy).toHaveBeenCalledWith(messages[1])
        expect(scrollIntoViewSpy).not.toHaveBeenCalledWith(messages[2])

        jasmine.clock().tick(progressiveDisclosureDelay)
        expect(messages[2]).not.toHaveClass('govuk-visually-hidden')
        expect(messages[2]).toHaveClass('app-c-conversation-message--fade-in')
        expect(scrollIntoViewSpy).toHaveBeenCalledWith(messages[2])

        // there is a delay after all work is done before promise is resolved
        jasmine.clock().tick(progressiveDisclosureDelay)
        promise.then(() => done())
      })
    })

    describe("when there aren't new messages", () => {
      it('delays before resolving the promise', async () => {
        const promise = module.progressivelyDiscloseMessages()
        await expectAsync(promise).toBePending()
        jasmine.clock().tick(progressiveDisclosureDelay)
        await expectAsync(promise).already.toBeResolved()
      })

      it("doesn't scroll to any elements", (done) => {
        const promise = module.progressivelyDiscloseMessages()
        expect(scrollIntoViewSpy).not.toHaveBeenCalled()
        jasmine.clock().tick(progressiveDisclosureDelay)
        promise.then(() => done())
      })
    })
  })

  describe('appendNewProgressivelyDisclosedMessages', () => {
    it('sets the HTML of the new messages list', done => {
      jasmine.clock().install()

      newMessagesList.innerHTML = '<!-- expecting this to be empty -->'
      const newHtml = '<li>A message</li>'
      const promise = module.appendNewProgressivelyDisclosedMessages(newHtml)
      jasmine.clock().tick(progressiveDisclosureDelay)
      promise.then(() => {
        expect(newMessagesList.innerHTML).toEqual(newHtml)
        jasmine.clock().uninstall()
        done()
      })
    })

    it('delegates to progressivelyDiscloseMessages to do the progressive disclosure', () => {
      const progressivelyDiscloseMessagesSpy = spyOn(module, 'progressivelyDiscloseMessages')
      module.appendNewProgressivelyDisclosedMessages('<li>Message</li>')
      expect(progressivelyDiscloseMessagesSpy).toHaveBeenCalled()
    })
  })

  describe('scrollToLastNewMessage', () => {
    describe('when there are new messages', () => {
      beforeEach(() => {
        newMessagesList.innerHTML = `
          <li class="js-conversation-message">Message</li>
          <li class="js-conversation-message">Message</li>
        `
      })

      it('scrolls to the last message', () => {
        const messages = newMessagesList.querySelectorAll('.js-conversation-message')
        module.scrollToLastNewMessage()
        expect(scrollIntoViewSpy).toHaveBeenCalledWith(messages[messages.length - 1])
      })
    })

    describe('when there are no messages in history', () => {
      beforeEach(() => {
        newMessagesList.innerHTML = ''
      })

      it("doesn't call scrollIntoView", () => {
        module.scrollToLastNewMessage()
        expect(scrollIntoViewSpy).not.toHaveBeenCalled()
      })
    })
  })

  describe('scrollToLastMessageInHistory', () => {
    describe('when there are messages in history', () => {
      beforeEach(() => {
        messageHistoryList.innerHTML = `
          <li class="js-conversation-message">Message</li>
          <li class="js-conversation-message">Message</li>
        `
      })

      it('scrolls to the last message', () => {
        const messages = messageHistoryList.querySelectorAll('.js-conversation-message')
        module.scrollToLastMessageInHistory()
        expect(scrollIntoViewSpy).toHaveBeenCalledWith(messages[messages.length - 1])
      })
    })

    describe('when there are no messages in history', () => {
      beforeEach(() => {
        messageHistoryList.innerHTML = ''
      })

      it("doesn't call scrollIntoView", () => {
        module.scrollToLastMessageInHistory()
        expect(scrollIntoViewSpy).not.toHaveBeenCalled()
      })
    })
  })

  describe('moveNewMessagesToHistory', () => {
    it('moves elements from the new messages list to the message history list', () => {
      // formatted to match innerHTML once moved
      const messagesHtml = [
        '<li class="js-conversation-message">Message</li>',
        '<li class="js-conversation-message">Message</li>',
        '<li class="js-conversation-message">Message</li>'
      ].join('')
      messageHistoryList.innerHTML = ''
      newMessagesList.innerHTML = messagesHtml

      module.moveNewMessagesToHistory()

      expect(newMessagesList.innerHTML.trim()).toEqual('')
      expect(messageHistoryList.innerHTML).toEqual(messagesHtml)
    })

    it('removes fade in class from elements that are being moved', () => {
      const messagesHtml = '<li class="js-conversation-message app-c-conversation-message--fade-in">A message</li>'
      messageHistoryList.innerHTML = ''
      newMessagesList.innerHTML = messagesHtml

      module.moveNewMessagesToHistory()

      const message = messageHistoryList.firstChild
      expect(message.textContent).toEqual('A message')
      expect(message).not.toHaveClass('app-c-conversation-message--fade-in')
    })
  })

  describe('renderQuestionLoading', () => {
    beforeEach(() => jasmine.clock().install())
    afterEach(() => jasmine.clock().uninstall())

    it('adds a loading element, after a delay, to the new messages list', () => {
      module.renderQuestionLoading()

      expect(newMessagesList.children).toHaveSize(0)

      jasmine.clock().tick(questionLoadingTimeout)

      expect(newMessagesList.children).toHaveSize(1)
      expect(newMessagesList.children[0].textContent).toEqual('Loading question')
    })

    it('scrolls to the loading element', () => {
      module.renderQuestionLoading()

      jasmine.clock().tick(questionLoadingTimeout)

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(newMessagesList.firstElementChild)
    })
  })

  describe('resetQuestionLoading', () => {
    it("removes question loading if it's present", () => {
      jasmine.clock().install()
      module.renderQuestionLoading()
      jasmine.clock().tick(500)

      const loadingElement = newMessagesList.firstElementChild
      expect(newMessagesList.contains(loadingElement)).toBe(true)

      module.resetQuestionLoading()

      expect(newMessagesList.contains(loadingElement)).toBe(false)
      jasmine.clock().uninstall()
    })

    it('prevents question loading from appearing after the delay', () => {
      const clearTimeoutSpy = spyOn(window, 'clearTimeout')
      module.renderQuestionLoading()
      module.resetQuestionLoading()
      expect(clearTimeoutSpy).toHaveBeenCalledWith(module.questionLoadingTimeout)
    })
  })

  describe('renderQuestion', () => {
    it('adds the HTML of the new question to the new messages list', () => {
      module.renderQuestion('<li>New question</li>')

      expect(newMessagesList.children).toHaveSize(1)
      expect(newMessagesList.children[0].textContent).toEqual('New question')
    })

    it('scrolls to the new question', () => {
      module.renderQuestion('<li>New question</li>')

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(newMessagesList.lastElementChild)
    })

    it('delegates to resetQuestionLoading to abort any question loading', () => {
      const resetQuestionLoadingSpy = spyOn(module, 'resetQuestionLoading')

      module.renderQuestion('<li>New question</li>')

      expect(resetQuestionLoadingSpy).toHaveBeenCalled()
    })
  })

  describe('renderAnswerLoading', () => {
    it('adds a loading element to the new messages list', () => {
      module.renderAnswerLoading()

      expect(newMessagesList.children).toHaveSize(1)
      expect(newMessagesList.children[0].textContent).toEqual('Loading answer')
    })

    it('scrolls to the loading element', () => {
      module.renderAnswerLoading()

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(newMessagesList.firstElementChild)
    })
  })

  describe('renderAnswer', () => {
    it('adds the HTML of the new answer to the new messages list', () => {
      module.renderAnswer('<li>New answer</li>')

      expect(newMessagesList.children).toHaveSize(1)
      expect(newMessagesList.children[0].textContent).toEqual('New answer')
    })

    it('scrolls to the new answer', () => {
      module.renderAnswer('<li>New answer</li>')

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(newMessagesList.lastElementChild)
    })

    it('initialises modules on the new messages list', () => {
      const modulesStartSpy = spyOn(window.GOVUK.modules, 'start')
      module.renderAnswer('<li>New answer</li>')

      expect(modulesStartSpy).toHaveBeenCalledWith(newMessagesList)
    })

    it("removes answer loading if it's present", () => {
      module.renderAnswerLoading()

      const loadingElement = newMessagesList.firstElementChild
      expect(newMessagesList.contains(loadingElement)).toBe(true)

      module.renderAnswer()

      expect(newMessagesList.contains(loadingElement)).toBe(false)
    })
  })
})

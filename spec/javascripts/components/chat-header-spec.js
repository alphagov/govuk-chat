describe('ChatHeader component', () => {
  'use strict'

  let module, header

  beforeEach(function () {
    header = document.createElement('header')
    document.body.appendChild(header)
    module = new window.GOVUK.Modules.ChatHeader(header)
  })

  afterEach(function () {
    document.body.removeChild(header)
  })

  describe('when document receives an event of conversation-active', () => {
    it('removes the focusable only class from the clear chat link', () => {
      const clearChatLink = document.createElement('a')
      clearChatLink.classList.add('js-header-clear-chat', 'app-c-header__clear-chat--focusable-only')
      header.prepend(clearChatLink)

      // reinitialise module as we've changed the underlying HTML
      module = new window.GOVUK.Modules.ChatHeader(header)
      module.init()

      document.dispatchEvent(new Event('conversation-active'))

      expect(clearChatLink).not.toHaveClass('app-c-header__clear-chat--focusable-only')
    })
  })
})

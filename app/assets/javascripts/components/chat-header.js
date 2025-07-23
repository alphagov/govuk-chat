window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class ChatHeader {
    constructor (module) {
      this.module = module
      this.clearChatLink = module.querySelector('.js-header-clear-chat')
    }

    init () {
      document.addEventListener('conversation-active', () => this.handleConversationActive())
    }

    handleConversationActive () {
      if (!this.clearChatLink) return

      this.clearChatLink.classList.remove('app-c-header__clear-chat--focusable-only')
    }
  }

  Modules.ChatHeader = ChatHeader
})(window.GOVUK.Modules)

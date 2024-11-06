window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  class ChatHeader {
    constructor (module) {
      this.module = module
      this.menuButton = module.querySelector('.govuk-js-header-toggle')
      this.navContainer = module.querySelector('.js-header-nav-container')
      this.navList = module.querySelector('.js-header-nav-container .govuk-header__navigation-list')
    }

    init () {
      if (this.module.dataset.addPrintUtility) {
        this.addPrintButton()
      }

      this.menuButton.addEventListener('click', e => this.handleClick(e))

      // set the initial state of the navigation menu
      this.menuButton.hidden = false
      this.menuButton.ariaExpanded = false
      this.navList.hidden = true
    }

    handleClick () {
      this.navList.hidden = !this.navList.hidden
      this.menuButton.ariaExpanded = !this.navList.hidden
      this.menuButton.classList.toggle('app-c-header__menu-button--expanded')
    }

    addPrintButton () {
      const li = document.createElement('li')
      li.className = 'govuk-header__navigation-item'

      const button = document.createElement('button')
      button.textContent = 'Print or save this chat'
      button.className = 'app-c-header__button app-c-header__button--print js-print-button'
      button.addEventListener('click', e => window.print())

      li.appendChild(button)

      const linkToInsertAbove = this.navList.querySelector('[data-after-print=true]')

      if (linkToInsertAbove) {
        this.navList.insertBefore(li, linkToInsertAbove.closest('li'))
      } else {
        this.navList.appendChild(li)
      }
    }
  }

  Modules.ChatHeader = ChatHeader
})(window.GOVUK.Modules)

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
      this.navListItems = module.querySelectorAll('.js-header-nav-container .govuk-header__navigation-item')
    }

    init () {
      this.menuButton.addEventListener('click', e => this.handleClick(e))

      // set the initial state of the navigation menu
      this.menuButton.hidden = false
      this.menuButton.ariaExpanded = false
      this.navList.hidden = true

      // removing/adding classes for styling the JS enhanced header
      this.navContainer.classList.remove('app-c-header__nav-container--float-right-desktop')
      this.navListItems.forEach(listItem => {
        listItem.classList.add('js-header-navigation-item')
      })
    }

    handleClick () {
      this.navList.hidden = !this.navList.hidden
      this.menuButton.ariaExpanded = !this.navList.hidden
      this.menuButton.classList.toggle('app-c-header__menu-button--expanded')
    }
  }

  Modules.ChatHeader = ChatHeader
})(window.GOVUK.Modules)

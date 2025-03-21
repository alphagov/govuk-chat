describe('ChatHeader component', () => {
  'use strict'

  let module, header, menuButton, navList, navListItems

  beforeEach(function () {
    header = document.createElement('header')
    header.innerHTML = `
      <div class="js-header-nav-container">
        <nav>
          <button class="govuk-js-header-toggle">Menu</button>
          <ul class="govuk-header__navigation-list">
            <li class="govuk-header__navigation-item"><a>Navigation item</a></li>
            <li class="govuk-header__navigation-item"><a>Navigation item</a></li>
            <li class="govuk-header__navigation-item"><a>Navigation item</a></li>
          </ul>
        </nav>
      </div>
    `
    document.body.appendChild(header)
    menuButton = header.querySelector('.govuk-js-header-toggle')
    navList = header.querySelector('.govuk-header__navigation-list')
    navListItems = header.querySelectorAll('.govuk-header__navigation-item')
    module = new window.GOVUK.Modules.ChatHeader(header)
  })

  afterEach(function () {
    document.body.removeChild(header)
  })

  describe('init', () => {
    it('shows the "menu" button', () => {
      module.init()

      expect(menuButton.hidden).toBe(false)
    })

    it('hides the navigation list', () => {
      module.init()

      expect(navList.hidden).toBe(true)
    })

    it('sets the menu button\'s initial aria-expanded value to false', () => {
      module.init()

      expect(menuButton.ariaExpanded).toBe('false')
    })

    describe('when "[data-add-print-utility]" is not present', () => {
      it('does not add the print button', () => {
        module.init()

        const printButton = header.querySelector('.js-print-button')
        expect(printButton).toBeNull()
      })
    })

    describe('when "[data-add-print-utility]" is present', () => {
      it('adds a list item to the nav list with a print button', () => {
        header.dataset.addPrintUtility = true
        module.init()

        const printButton = navList.lastElementChild.querySelector('button.js-print-button')
        const updatedNavListItems = header.querySelectorAll('.govuk-header__navigation-item')

        expect(updatedNavListItems.length).toEqual(navListItems.length + 1)
        expect(printButton.textContent).toEqual('Print or save this chat')
      })

      it('adds a list item to the nav list with a print button after a link with data-after-print=true', () => {
        header.dataset.addPrintUtility = true
        navList.querySelector('li:nth-child(2) a').dataset.afterPrint = true

        module.init()

        // Print button has been added above the 2nd nav item, so it's now the 2nd nav item
        const printButton = navList.querySelector('li:nth-child(2) button')
        expect(printButton.textContent).toEqual('Print or save this chat')
      })
    })
  })

  describe('when the menu button is clicked', () => {
    describe('the first time', () => {
      it('shows the navigation list', () => {
        module.init()
        menuButton.dispatchEvent(new Event('click'))

        expect(navList.hidden).toBe(false)
      })

      it('sets the menu button\'s aria-expanded attribute to true', () => {
        module.init()
        menuButton.dispatchEvent(new Event('click'))

        expect(menuButton.ariaExpanded).toBe('true')
      })

      it('adds the "app-c-header__menu-button--expanded" class to the menu button', () => {
        module.init()
        menuButton.dispatchEvent(new Event('click'))

        expect(menuButton.classList).toContain('app-c-header__menu-button--expanded')
      })
    })

    describe('the second time', () => {
      it('hides the navigation list', () => {
        module.init()
        menuButton.dispatchEvent(new Event('click'))
        menuButton.dispatchEvent(new Event('click'))

        expect(navList.hidden).toBe(true)
      })

      it('sets the menu button\'s aria-expanded attribute to false', () => {
        module.init()
        menuButton.dispatchEvent(new Event('click'))
        menuButton.dispatchEvent(new Event('click'))

        expect(menuButton.ariaExpanded).toBe('false')
      })

      it('removes the "app-c-header__menu-button--expanded" class from the menu button', () => {
        module.init()
        menuButton.dispatchEvent(new Event('click'))
        menuButton.dispatchEvent(new Event('click'))

        expect(menuButton.classList).not.toContain('app-c-header__menu-button--expanded')
      })
    })
  })

  describe('when the print button is clicked', () => {
    it('calls the DOM print API', () => {
      header.dataset.addPrintUtility = true
      const printDialogSpy = spyOn(window, 'print')

      module.init()
      const printButton = header.querySelector('.js-print-button')

      printButton.dispatchEvent(new Event('click'))

      expect(printDialogSpy).toHaveBeenCalled()
    })
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

describe('ChatHeader component', () => {
  'use strict'

  let module, header, menuButton, navContainer, navList, navListItems

  beforeEach(function () {
    header = document.createElement('header')
    header.innerHTML = `
      <div class="app-c-header__nav-container--float-right-desktop js-header-nav-container">
        <nav>
          <button class="govuk-js-header-toggle">Menu</button>
          <ul class="govuk-header__navigation-list">
            <li class="govuk-header__navigation-item">Navigation item</li>
            <li class="govuk-header__navigation-item">Navigation item</li>
            <li class="govuk-header__navigation-item">Navigation item</li>
          </ul>
        </nav>
      </div>
    `
    document.body.appendChild(header)
    menuButton = header.querySelector('.govuk-js-header-toggle')
    navContainer = header.querySelector('.js-header-nav-container')
    navList = header.querySelector('.js-header-nav-container .govuk-header__navigation-list')
    navListItems = header.querySelectorAll('.js-header-nav-container .govuk-header__navigation-item')
    module = new window.GOVUK.Modules.ChatHeader(header)
  })

  afterEach(function () {
    document.body.removeChild(header)
  })

  describe('init', () => {
    beforeEach(() => {
      module.init()
    })

    it('shows the "menu" button', () => {
      expect(menuButton.hidden).toBe(false)
    })

    it('hides the navigation list', () => {
      expect(navList.hidden).toBe(true)
    })

    it('sets the menu button\'s initial aria-expanded value to false', () => {
      expect(menuButton.ariaExpanded).toBe('false')
    })

    it('removes the "app-c-header__nav-container--float-right-desktop" class from the nav container', () => {
      expect(navContainer.classList).not.toContain('app-c-header__nav-container--float-right-desktop')
    })

    it('adds a "js-header-navigation-item" class to each list item', () => {
      navListItems.forEach(navListItem => {
        expect(navListItem.classList).toContain('js-header-navigation-item')
      })
    })
  })

  describe('when the menu button is clicked', () => {
    beforeEach(() => {
      module.init()
      menuButton.dispatchEvent(new Event('click'))
    })

    describe('the first time', () => {
      it('shows the navigation list', () => {
        expect(navList.hidden).toBe(false)
      })

      it('sets the menu button\'s aria-expanded attribute to true', () => {
        expect(menuButton.ariaExpanded).toBe('true')
      })

      it('adds the "app-c-header__menu-button--expanded" class to the menu button', () => {
        expect(menuButton.classList).toContain('app-c-header__menu-button--expanded')
      })
    })

    describe('the second time', () => {
      beforeEach(() => {
        menuButton.dispatchEvent(new Event('click'))
      })

      it('hides the navigation list', () => {
        expect(navList.hidden).toBe(true)
      })

      it('sets the menu button\'s aria-expanded attribute to false', () => {
        expect(menuButton.ariaExpanded).toBe('false')
      })

      it('removes the "app-c-header__menu-button--expanded" class from the menu button', () => {
        expect(menuButton.classList).not.toContain('app-c-header__menu-button--expanded')
      })
    })
  })

  describe('print button', () => {
    describe('when ".add-js-print-utility" is not present', () => {
      it('does not add the print button', () => {
        const addPrintButtonSpy = spyOn(module, 'addPrintButton')
        module.init()
        const printButton = header.querySelector('.js-print-button')

        expect(addPrintButtonSpy).not.toHaveBeenCalled()
        expect(printButton).toBeNull()
      })
    })

    describe('when ".add-js-print-utility" is present', () => {
      beforeEach(function () {
        navContainer.classList.add('js-add-print-utility')
      })

      it('adds the print button', () => {
        const addPrintButtonSpy = spyOn(module, 'addPrintButton').and.callThrough()
        module.init()
        const printButton = header.querySelector('.js-print-button')

        expect(addPrintButtonSpy).toHaveBeenCalled()
        expect(printButton).toBeTruthy()
      })

      it('calls the DOM print API when clicked', () => {
        const printDialogSpy = spyOn(window, 'print')
        module.init()
        const printButton = header.querySelector('.js-print-button')

        printButton.dispatchEvent(new Event('click'))

        expect(printDialogSpy).toHaveBeenCalled()
      })
    })
  })
})

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

    it('removes the "app-c-header__nav-container--float-right-desktop" class from the nav container', () => {
      module.init()

      expect(navContainer.classList).not.toContain('app-c-header__nav-container--float-right-desktop')
    })

    it('adds a "js-header-navigation-item" class to each list item', () => {
      module.init()

      navListItems.forEach(navListItem => {
        expect(navListItem.classList).toContain('js-header-navigation-item')
      })
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
        const updatedNavListItems = header.querySelectorAll('.js-header-nav-container .govuk-header__navigation-item')

        expect(updatedNavListItems.length).toEqual(navListItems.length + 1)
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
})

describe('ConversationForm component', () => {
  'use strict'

  let div, form, formGroup, input, button, presenceErrorMessage,
    lengthErrorMessage, errorsWrapper, surveyLink, module

  beforeEach(function () {
    div = document.createElement('div')
    presenceErrorMessage = 'Enter a question'
    lengthErrorMessage = 'Question must be 300 characters or less'
    div.dataset.presenceErrorMessage = presenceErrorMessage
    div.dataset.lengthErrorMessage = lengthErrorMessage
    div.dataset.maxlength = 300
    div.innerHTML = `
      <form class="js-conversation-form">
        <div class="js-conversation-form-group">
          <ul class="js-conversation-form-errors-wrapper" hidden="true"></ul>
          <input type="text" class="js-conversation-form-input" value="What is the VAT rate?">
          <button class="js-conversation-form-button">Submit</button>
        </div>
      </form>
      <a href="/survey" class="js-survey-link">Survey</a>
    `
    form = div.querySelector('.js-conversation-form')
    input = div.querySelector('.js-conversation-form-input')
    button = div.querySelector('.js-conversation-form-button')
    errorsWrapper = div.querySelector('.js-conversation-form-errors-wrapper')
    formGroup = div.querySelector('.js-conversation-form-group')
    surveyLink = div.querySelector('.js-survey-link')
    document.body.appendChild(div)
    module = new window.GOVUK.Modules.ConversationForm(div)
  })

  afterEach(function () {
    document.body.removeChild(div)
  })

  describe('init', () => {
    it('dispatches an init event on the module', () => {
      const spy = jasmine.createSpy()
      div.addEventListener('init', spy)

      module.init()

      expect(spy).toHaveBeenCalled()
    })
  })

  describe('when the form receives a submit event', () => {
    beforeEach(() => module.init())

    it('allows form submission when input is valid', () => {
      input.value = 'valid input'
      const submitSpy = jasmine.createSpy('submit event spy')
      form.addEventListener('submit', submitSpy)

      form.dispatchEvent(new Event('submit'))

      expect(submitSpy).toHaveBeenCalled()
    })

    it("prevents form submission when the form isn't valid", () => {
      input.value = ''
      const submitSpy = jasmine.createSpy('submit event spy')
      form.addEventListener('submit', submitSpy)
      const event = new Event('submit')
      spyOn(event, 'preventDefault')

      form.dispatchEvent(event)

      expect(event.preventDefault).toHaveBeenCalled()
      expect(submitSpy).not.toHaveBeenCalled()
    })

    it('shows an error when the user input is empty', () => {
      input.value = ''
      form.dispatchEvent(new Event('submit'))
      expect(errorsWrapper.hidden).toBe(false)

      expect(errorsWrapper.innerHTML)
        .toEqual(`<li><span class="govuk-visually-hidden">Error:</span>${presenceErrorMessage}</li>`)
    })

    it('adds the appropriate classes when there is a validation error', () => {
      input.value = ''
      form.dispatchEvent(new Event('submit'))

      expect(formGroup.classList).toContain('app-c-conversation-form__form-group--error')
      expect(input.classList).toContain('app-c-conversation-form__input--error')
    })

    it('removes any errors and error classes when input is valid', () => {
      input.value = ''
      form.dispatchEvent(new Event('submit'))

      input.value = 'valid input'
      form.dispatchEvent(new Event('submit'))

      expect(errorsWrapper.hidden).toBe(true)
      expect(errorsWrapper.innerHTML).toBe('')
      expect(formGroup.classList).not.toContain('app-c-conversation-form__form-group--error')
      expect(input.classList).not.toContain('app-c-conversation-form__input--error')
    })

    it('shows an error when the user input is greater in length than maxlength', () => {
      const maxlength = parseInt(div.dataset.maxlength, 10)
      input.value = 'a'.repeat(maxlength + 1)
      form.dispatchEvent(new Event('submit'))
      expect(errorsWrapper.hidden).toBe(false)

      expect(errorsWrapper.innerHTML)
        .toEqual(`<li><span class="govuk-visually-hidden">Error:</span>${lengthErrorMessage}</li>`)
    })
  })

  describe('when receiving a question-pending event', () => {
    beforeEach(() => module.init())

    it('disables the controls', () => {
      div.dispatchEvent(new Event('question-pending'))

      expect(input.readOnly).toBe(true)
      expect(button.disabled).toBe(true)
    })

    it("doesn't update the input value", () => {
      const value = input.value
      div.dispatchEvent(new Event('question-pending'))

      expect(input.value).toEqual(value)
    })
  })

  describe('when receiving a question-accepted event', () => {
    beforeEach(() => module.init())

    it('disables the controls', () => {
      div.dispatchEvent(new Event('question-accepted'))

      expect(input.readOnly).toBe(true)
      expect(button.disabled).toBe(true)
    })

    it('resets the input value', () => {
      div.dispatchEvent(new Event('question-accepted'))

      expect(input.value).toEqual('')
    })

    it('updates the survey link to add the value of the conversation_id cookie', () => {
      const cookieSpy = spyOn(window.GOVUK, 'cookie')
      cookieSpy.withArgs('conversation_id').and.returnValue('1234-1234-1234')

      div.dispatchEvent(new Event('question-accepted'))
      expect(surveyLink.href).toMatch(/\?conversation=1234-1234-1234$/)
    })
  })

  describe('when receiving a question-rejected event', () => {
    let errorDetail

    beforeEach(() => {
      module.init()
      errorDetail = {
        detail: {
          errorMessages: ['Error 1', 'Error 2']
        }
      }
    })

    it('enables any disabled controls', () => {
      input.readOnly = true
      button.disabled = true

      div.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

      expect(input.readOnly).toBe(false)
      expect(button.disabled).toBe(false)
    })

    it("doesn't update the input value", () => {
      const value = input.value
      div.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

      expect(input.value).toEqual(value)
    })

    it('displays error messages provided by the event', () => {
      const event = new CustomEvent('question-rejected', errorDetail)
      div.dispatchEvent(event)

      const expectedHtml = '<li><span class="govuk-visually-hidden">Error:</span>Error 1</li>' +
        '<li><span class="govuk-visually-hidden">Error:</span>Error 2</li>'

      expect(errorsWrapper.hidden).toBe(false)
      expect(errorsWrapper.innerHTML).toEqual(expectedHtml)
    })

    it('adds the appropriate classes when there is a validation error', () => {
      const event = new CustomEvent('question-rejected', errorDetail)
      div.dispatchEvent(event)

      expect(formGroup.classList).toContain('app-c-conversation-form__form-group--error')
      expect(input.classList).toContain('app-c-conversation-form__input--error')
    })

    it('replaces any existing error messages', () => {
      errorsWrapper.hidden = false
      errorsWrapper.innerHTML = '<li><span class="govuk-visually-hidden">Error:</span>Oops</li>'
      div.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

      expect(errorsWrapper.hidden).toBe(false)
      expect(errorsWrapper.textContent).not.toMatch(/Oops/)
    })

    it("raises an error if the event doesn't have an errorMessages detail", () => {
      const errorMessage = 'expected event detail containing errorMessages'

      // calling event handler directly as using element.dispatchEvent raises
      // the error globally and it's unclear how to catch that.

      expect(() => { module.handleQuestionRejected(new Event('question-rejected')) })
        .toThrowError(errorMessage)

      const customEvent = new CustomEvent('question-rejected', { detail: { errorMessages: null } })
      expect(() => { module.handleQuestionRejected(customEvent) })
        .toThrowError(errorMessage)
    })
  })

  describe('when receiving an answer-received event', () => {
    beforeEach(() => module.init())

    it('enables any disabled controls', () => {
      input.readOnly = true
      button.disabled = true

      div.dispatchEvent(new Event('answer-received'))

      expect(input.readOnly).toBe(false)
      expect(button.disabled).toBe(false)
    })

    it('resets the value of the input', () => {
      div.dispatchEvent(new Event('answer-received'))

      expect(input.value).toEqual('')
    })
  })
})

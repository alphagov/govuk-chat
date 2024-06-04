describe('Conversation form component', () => {
  'use strict'

  let form, input, button, presenceErrorMessage, lengthErrorMessage, errorsWrapper, module

  beforeEach(function () {
    form = document.createElement('form')
    presenceErrorMessage = 'Enter a question'
    lengthErrorMessage = 'Question must be 300 characters or less'
    form.dataset.presenceErrorMessage = presenceErrorMessage
    form.dataset.lengthErrorMessage = lengthErrorMessage
    form.dataset.maxlength = 300
    form.innerHTML = `
      <input type="text" class="js-conversation-form-input" value="What is the VAT rate?">
      <button class="js-conversation-form-button">Submit</button>
      <ul class="js-conversation-form-errors-wrapper" hidden="true"></ul>
    `
    input = form.querySelector('.js-conversation-form-input')
    button = form.querySelector('.js-conversation-form-button')
    errorsWrapper = form.querySelector('.js-conversation-form-errors-wrapper')
    document.body.appendChild(form)
    module = new window.GOVUK.Modules.ConversationForm(form)
  })

  afterEach(function () {
    document.body.removeChild(form)
  })

  describe('init', () => {
    it('dispatches an init event on the form element', () => {
      const spy = jasmine.createSpy()
      form.addEventListener('init', spy)

      module.init()

      expect(spy).toHaveBeenCalled()
    })
  })

  describe('receiving the submit event', () => {
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

    it('shows an error when the user input is greater in length than maxlength', () => {
      const maxlength = parseInt(form.dataset.maxlength, 10)
      input.value = 'a'.repeat(maxlength + 1)
      form.dispatchEvent(new Event('submit'))
      expect(errorsWrapper.hidden).toBe(false)

      expect(errorsWrapper.innerHTML)
        .toEqual(`<li><span class="govuk-visually-hidden">Error:</span>${lengthErrorMessage}</li>`)
    })
  })

  describe('receiving the question-pending event', () => {
    beforeEach(() => module.init())

    it('disables the controls', () => {
      form.dispatchEvent(new Event('question-pending'))

      expect(input.readOnly).toBe(true)
      expect(button.disabled).toBe(true)
    })

    it("doesn't update the input value", () => {
      const value = input.value
      form.dispatchEvent(new Event('question-pending'))

      expect(input.value).toEqual(value)
    })
  })

  describe('receiving the question-accepted event', () => {
    beforeEach(() => module.init())

    it('disables the controls', () => {
      form.dispatchEvent(new Event('question-accepted'))

      expect(input.readOnly).toBe(true)
      expect(button.disabled).toBe(true)
    })

    it('resets the input value', () => {
      form.dispatchEvent(new Event('question-accepted'))

      expect(input.value).toEqual('')
    })
  })

  describe('receiving the question-rejected event', () => {
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

      form.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

      expect(input.readOnly).toBe(false)
      expect(button.disabled).toBe(false)
    })

    it("doesn't update the input value", () => {
      const value = input.value
      form.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

      expect(input.value).toEqual(value)
    })

    it('displays error messages provided by the event', () => {
      const event = new CustomEvent('question-rejected', errorDetail)
      form.dispatchEvent(event)

      const expectedHtml = '<li><span class="govuk-visually-hidden">Error:</span>Error 1</li>' +
        '<li><span class="govuk-visually-hidden">Error:</span>Error 2</li>'

      expect(errorsWrapper.hidden).toBe(false)
      expect(errorsWrapper.innerHTML).toEqual(expectedHtml)
    })

    it('replaces any existing error messages', () => {
      errorsWrapper.hidden = false
      errorsWrapper.innerHTML = '<li><span class="govuk-visually-hidden">Error:</span>Oops</li>'
      form.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

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

  describe('receiving the answer-received event', () => {
    beforeEach(() => module.init())

    it('enables any disabled controls', () => {
      input.readOnly = true
      button.disabled = true

      form.dispatchEvent(new Event('answer-received'))

      expect(input.readOnly).toBe(false)
      expect(button.disabled).toBe(false)
    })

    it('resets the value of the input', () => {
      form.dispatchEvent(new Event('answer-received'))

      expect(input.value).toEqual('')
    })
  })
})

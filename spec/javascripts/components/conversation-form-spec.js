describe('Conversation form component', () => {
  'use strict'

  let form, input, button, presenceErrorMessage, errorsWrapper

  beforeEach(function () {
    form = document.createElement('form')
    presenceErrorMessage = 'Enter a question'
    form.dataset.presenceErrorMessage = presenceErrorMessage
    form.innerHTML = `
      <input type="text" class="js-conversation-form-input" value="What is the VAT rate?">
      <button class="js-conversation-form-button">Submit</button>
      <ul class="js-conversation-form-errors-wrapper" hidden="true"></ul>
    `
    input = form.querySelector('.js-conversation-form-input')
    button = form.querySelector('.js-conversation-form-button')
    errorsWrapper = form.querySelector('.js-conversation-form-errors-wrapper')
    document.body.appendChild(form)
    new window.GOVUK.Modules.ConversationForm(form).init()
  })

  afterEach(function () {
    document.body.removeChild(form)
  })

  describe('receiving the submit event', () => {
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
  })

  describe('receiving the question-pending event', () => {
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
    it('enables any disabled controls', () => {
      input.readOnly = true
      button.disabled = true

      form.dispatchEvent(new Event('question-rejected'))

      expect(input.readOnly).toBe(false)
      expect(button.disabled).toBe(false)
    })

    it("doesn't update the input value", () => {
      const value = input.value
      form.dispatchEvent(new Event('question-rejected'))

      expect(input.value).toEqual(value)
    })
  })

  describe('receiving the answer-received event', () => {
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

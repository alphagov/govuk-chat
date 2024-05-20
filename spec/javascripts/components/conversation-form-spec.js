describe('Conversation form component', () => {
  'use strict'

  let form, input, button

  beforeEach(function () {
    form = document.createElement('form')
    form.innerHTML = `
      <input type="text" class="js-conversation-form-input" value="What is the VAT rate?">
      <button class="js-conversation-form-button">Submit</button>
    `
    input = form.querySelector('.js-conversation-form-input')
    button = form.querySelector('.js-conversation-form-button')
    document.body.appendChild(form)
    new window.GOVUK.Modules.ConversationForm(form).init()
  })

  afterEach(function () {
    document.body.removeChild(form)
  })

  describe('receiving the question-pending event', () => {
    it('disables the controls', () => {
      form.dispatchEvent(new Event('question-pending'))

      expect(input.disabled).toBe(true)
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

      expect(input.disabled).toBe(true)
      expect(button.disabled).toBe(true)
    })

    it('resets the input value', () => {
      form.dispatchEvent(new Event('question-accepted'))

      expect(input.value).toEqual('')
    })
  })

  describe('receiving the question-rejected event', () => {
    it('enables any disabled controls', () => {
      input.disabled = true
      button.disabled = true

      form.dispatchEvent(new Event('question-rejected'))

      expect(input.disabled).toBe(false)
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
      input.disabled = true
      button.disabled = true

      form.dispatchEvent(new Event('answer-received'))

      expect(input.disabled).toBe(false)
      expect(button.disabled).toBe(false)
    })

    it('resets the value of the input', () => {
      form.dispatchEvent(new Event('answer-received'))

      expect(input.value).toEqual('')
    })
  })
})

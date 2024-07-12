describe('ConversationForm component', () => {
  'use strict'

  let div, form, formGroup, label, input, button, presenceErrorMessage,
    lengthErrorMessage, errorsWrapper, surveyLink, module

  beforeEach(function () {
    div = document.createElement('div')
    presenceErrorMessage = 'Enter a question'
    lengthErrorMessage = 'Question must be 300 characters or less'
    div.dataset.presenceErrorMessage = presenceErrorMessage
    div.dataset.lengthErrorMessage = lengthErrorMessage
    div.dataset.maxlength = 300
    div.dataset.hintId = 'create_question_user_question-info'
    div.innerHTML = `
      <form class="js-conversation-form">
        <div class="js-conversation-form-group">
          <ul id="create_question_user_question-error" class="js-conversation-form-errors-wrapper" hidden="true"></ul>
          <label class="js-conversation-form-label">Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)</label>
          <input type="text" class="js-conversation-form-input govuk-js-character-count" id="create_question_user_question" value="What is the VAT rate?" aria-describedby="create_question_user_question-info create_question_user_question-error">
          <div id="create_question_user_question-info" class="gem-c-hint govuk-hint govuk-visually-hidden">
            Please limit your question to 300 characters.
          </div>
          <button class="js-conversation-form-button">Submit</button>
        </div>
      </form>
      <a href="/survey" class="js-survey-link">Survey</a>
    `
    form = div.querySelector('.js-conversation-form')
    label = div.querySelector('.js-conversation-form-label')
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

    it('sets the input/s aria-describedby attribute to only reference hint text', () => {
      expect(input.getAttribute('aria-describedby')).toBe('create_question_user_question-info create_question_user_question-error')

      module.init()

      expect(input.getAttribute('aria-describedby')).toBe('create_question_user_question-info')
      expect(input.getAttribute('aria-describedby')).not.toContain('create_question_user_question-error')
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

    it('prevents form submission when the input is empty', () => {
      input.value = ''
      const submitSpy = jasmine.createSpy('submit event spy')
      form.addEventListener('submit', submitSpy)
      const event = new Event('submit')
      spyOn(event, 'preventDefault')

      form.dispatchEvent(event)

      expect(event.preventDefault).toHaveBeenCalled()
      expect(submitSpy).not.toHaveBeenCalled()
    })

    it('prevents form submission when the input exceeds the max character count', () => {
      const maxlength = parseInt(div.dataset.maxlength, 10)
      input.value = 'a'.repeat(maxlength + 1)

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

    it('hides the regular label and references the error messages via aria-labelledby when the user input is empty', () => {
      input.value = ''
      form.dispatchEvent(new Event('submit'))

      expect(label.ariaHidden).toBe('true')
      expect(input.getAttribute('aria-labelledby')).toBe('create_question_user_question-error')
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

    it('restores the regular label when input is valid', () => {
      input.value = ''
      form.dispatchEvent(new Event('submit'))

      input.value = 'valid input'
      form.dispatchEvent(new Event('submit'))

      expect(label.ariaHidden).toBe('false')
      expect(input.getAttribute('aria-labelledby')).toBe(null)
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

    it('hides the character count hint', () => {
      // Type in enough characters to make the hint show on screen
      input.value = 'A'.repeat(280)
      input.dispatchEvent(new Event('keyup'))
      expect(form.innerHTML).toContain('You have 20 characters remaining')

      div.dispatchEvent(new Event('question-accepted'))

      expect(form.innerHTML).not.toContain('You have 20 characters remaining')
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

    it('hides the regular label and references the error messages provided by the event via aria-labelledby', () => {
      const event = new CustomEvent('question-rejected', errorDetail)
      div.dispatchEvent(event)

      expect(label.ariaHidden).toBe('true')
      expect(input.getAttribute('aria-labelledby')).toBe('create_question_user_question-error')
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

    it('hides the character count hint', () => {
      // Type in enough characters to make the hint show on screen
      input.value = 'A'.repeat(280)
      input.dispatchEvent(new Event('keyup'))
      expect(form.innerHTML).toContain('You have 20 characters remaining')

      div.dispatchEvent(new Event('answer-received'))

      expect(form.innerHTML).not.toContain('You have 20 characters remaining')
    })
  })
})

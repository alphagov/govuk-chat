describe('QuestionForm component', () => {
  'use strict'

  let div, form, formGroup, textareaWrapper, textarea, button, buttonResponseStatus, presenceErrorMessage,
    lengthErrorMessage, errorsWrapper, module

  beforeEach(function () {
    div = document.createElement('div')
    presenceErrorMessage = 'Enter a question'
    lengthErrorMessage = 'Question must be 300 characters or less'
    div.dataset.presenceErrorMessage = presenceErrorMessage
    div.dataset.lengthErrorMessage = lengthErrorMessage
    div.dataset.maxlength = 300
    div.dataset.hintId = 'create_question_user_question-info'
    div.innerHTML = `
      <form class="js-question-form">
        <div class="js-question-form-group">
          <ul id="create_question_user_question-error" class="js-question-form-errors-wrapper" hidden="true"></ul>
          <div class="js-question-form-textarea-wrapper" data-replicated-value="What is the VAT rate?">
            <textarea class="js-question-form-textarea govuk-js-character-count" id="create_question_user_question">What is the VAT rate?</textarea>
            <div id="create_question_user_question-info" class="gem-c-hint govuk-hint govuk-visually-hidden">
              Please limit your question to 300 characters.
            </div>
          </div>
          <button class="js-question-form-button">
            Submit
          </button>
          <span data-loading-question-text="Loading your question" data-loading-answer-text="Generating your answer" class="js-question-form-button__response-status"></span>
        </div>
      </form>
      <a href="/survey" class="js-survey-link">Survey</a>
    `
    form = div.querySelector('.js-question-form')
    textarea = div.querySelector('.js-question-form-textarea')
    textareaWrapper = div.querySelector('.js-question-form-textarea-wrapper')
    button = div.querySelector('.js-question-form-button')
    button = div.querySelector('.js-question-form-button')
    buttonResponseStatus = div.querySelector('.js-question-form-button__response-status')
    errorsWrapper = div.querySelector('.js-question-form-errors-wrapper')
    formGroup = div.querySelector('.js-question-form-group')
    document.body.appendChild(div)
    module = new window.GOVUK.Modules.QuestionForm(div)
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

  describe('when the enter key is pressed', () => {
    it('the form is submitted', () => {
      module.init()

      const submitSpy = jasmine.createSpy('submit event spy')
      form.addEventListener('submit', submitSpy)

      const enterKeydown = new KeyboardEvent('keydown', {
        key: 'Enter'
      })

      textarea.dispatchEvent(enterKeydown)

      expect(submitSpy).toHaveBeenCalled()
    })
  })

  describe('when the enter key and shift key is pressed', () => {
    it('the form is not submitted', () => {
      module.init()

      const submitSpy = jasmine.createSpy('submit event spy')
      form.addEventListener('submit', submitSpy)

      const enterAndShiftKeydown = new KeyboardEvent('keydown', {
        key: 'Enter',
        shiftKey: true
      })

      textarea.dispatchEvent(enterAndShiftKeydown)

      expect(submitSpy).not.toHaveBeenCalled()
    })
  })

  describe('when the textarea receives input', () => {
    it('updates the wrapper data attribute', () => {
      module.init()

      textarea.value = 'valid input'
      textarea.dispatchEvent(new Event('input'))

      expect(textareaWrapper.dataset.replicatedValue).toEqual(textarea.value)
    })
  })

  describe('when the form receives a submit event', () => {
    beforeEach(() => module.init())

    it('allows form submission when input is valid', () => {
      textarea.value = 'valid input'
      const submitSpy = jasmine.createSpy('submit event spy')
      form.addEventListener('submit', submitSpy)

      form.dispatchEvent(new Event('submit'))

      expect(submitSpy).toHaveBeenCalled()
    })

    it('prevents form submission when the input is empty', () => {
      textarea.value = ''
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
      textarea.value = 'a'.repeat(maxlength + 1)

      const submitSpy = jasmine.createSpy('submit event spy')
      form.addEventListener('submit', submitSpy)
      const event = new Event('submit')
      spyOn(event, 'preventDefault')

      form.dispatchEvent(event)

      expect(event.preventDefault).toHaveBeenCalled()
      expect(submitSpy).not.toHaveBeenCalled()
    })

    it('shows an error when the user input is empty', () => {
      textarea.value = ''
      form.dispatchEvent(new Event('submit'))
      expect(errorsWrapper.hidden).toBe(false)

      expect(errorsWrapper.innerHTML)
        .toEqual(`<li class="app-c-question-form__error-message"><span class="govuk-visually-hidden">Error:</span>${presenceErrorMessage}</li>`)
    })

    it('updates the textarea\'s aria-describedby attribute to also reference the error id when errors occur (e.g. input is empty)', () => {
      textarea.value = ''
      form.dispatchEvent(new Event('submit'))
      expect(errorsWrapper.hidden).toBe(false)
      expect(textarea.getAttribute('aria-describedby')).toBe('create_question_user_question-info create_question_user_question-error')
    })

    it('adds the appropriate classes when there is a validation error', () => {
      textarea.value = ''
      form.dispatchEvent(new Event('submit'))

      expect(formGroup.classList).toContain('app-c-question-form__form-group--error')
      expect(textarea.classList).toContain('app-c-question-form__textarea--error')
    })

    it('removes any errors and error classes when input is valid', () => {
      textarea.value = ''
      form.dispatchEvent(new Event('submit'))

      textarea.value = 'valid input'
      form.dispatchEvent(new Event('submit'))

      expect(errorsWrapper.hidden).toBe(true)
      expect(errorsWrapper.innerHTML).toBe('')
      expect(formGroup.classList).not.toContain('app-c-question-form__form-group--error')
      expect(textarea.classList).not.toContain('app-c-question-form__textarea--error')
    })

    it('resets the textarea\'s aria-describedby attribute to only reference the hint id when input is valid', () => {
      textarea.value = ''
      form.dispatchEvent(new Event('submit'))

      textarea.value = 'valid input'
      form.dispatchEvent(new Event('submit'))

      expect(textarea.getAttribute('aria-describedby')).toBe('create_question_user_question-info')
    })
  })

  describe('when receiving a question-pending event', () => {
    beforeEach(() => module.init())

    it('disables the controls', () => {
      div.dispatchEvent(new Event('question-pending'))

      expect(textarea.readOnly).toBe(true)
      expect(button.hasAttribute('aria-disabled')).toBe(true)
      expect(button.classList).toContain('app-c-blue-button--disabled')
      expect(buttonResponseStatus.textContent).toContain('Loading your question')
    })

    it("doesn't update the input value", () => {
      const value = textarea.value
      div.dispatchEvent(new Event('question-pending'))

      expect(textarea.value).toEqual(value)
    })
  })

  describe('when receiving a question-accepted event', () => {
    beforeEach(() => module.init())

    it('disables the controls', () => {
      div.dispatchEvent(new Event('question-accepted'))

      expect(textarea.readOnly).toBe(true)
      expect(button.hasAttribute('aria-disabled')).toBe(true)
      expect(button.classList).toContain('app-c-blue-button--disabled')
      expect(buttonResponseStatus.textContent).toContain('Generating your answer')
    })

    it('resets the input value', () => {
      div.dispatchEvent(new Event('question-accepted'))

      expect(textarea.value).toEqual('')
    })

    it('resets the data-replicated-value attribute on the textarea wrapper', () => {
      div.dispatchEvent(new Event('question-accepted'))

      expect(textareaWrapper.dataset.replicatedValue).toEqual('')
    })

    it('hides the character count hint', () => {
      // Type in enough characters to make the hint show on screen
      textarea.value = 'A'.repeat(280)
      textarea.dispatchEvent(new Event('keyup'))
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
      textarea.readOnly = true
      button.setAttribute('aria-disabled', true)
      button.classList.add('app-c-blue-button--disabled')
      buttonResponseStatus.textContent = 'Visually hidden text content'

      div.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

      expect(textarea.readOnly).toBe(false)
      expect(button.hasAttribute('aria-disabled')).toBe(false)
      expect(button.classList).not.toContain('app-c-blue-button--disabled')
      expect(buttonResponseStatus.textContent).toEqual('')
    })

    it("doesn't update the input value", () => {
      const value = textarea.value
      div.dispatchEvent(new CustomEvent('question-rejected', errorDetail))

      expect(textarea.value).toEqual(value)
    })

    it('displays error messages provided by the event', () => {
      const event = new CustomEvent('question-rejected', errorDetail)
      div.dispatchEvent(event)

      const expectedHtml = '<li class="app-c-question-form__error-message"><span class="govuk-visually-hidden">Error:</span>Error 1</li>' +
        '<li class="app-c-question-form__error-message"><span class="govuk-visually-hidden">Error:</span>Error 2</li>'

      expect(errorsWrapper.hidden).toBe(false)
      expect(errorsWrapper.innerHTML).toEqual(expectedHtml)
    })

    it('adds the appropriate classes when there is a validation error', () => {
      const event = new CustomEvent('question-rejected', errorDetail)
      div.dispatchEvent(event)

      expect(formGroup.classList).toContain('app-c-question-form__form-group--error')
      expect(textarea.classList).toContain('app-c-question-form__textarea--error')
    })

    it('replaces any existing error messages', () => {
      errorsWrapper.hidden = false
      errorsWrapper.innerHTML = '<li class="app-c-question-form__error-message"><span class="govuk-visually-hidden">Error:</span>Oops</li>'
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
      textarea.readOnly = true
      button.setAttribute('aria-disabled', true)
      button.classList.add('app-c-blue-button--disabled')
      buttonResponseStatus.textContent = 'Visually hidden text content'

      div.dispatchEvent(new Event('answer-received'))

      expect(textarea.readOnly).toBe(false)
      expect(button.hasAttribute('aria-disabled')).toBe(false)
      expect(button.classList).not.toContain('app-c-blue-button--disabled')
      expect(buttonResponseStatus.textContent).toEqual('')
    })

    it('resets the value of the input', () => {
      div.dispatchEvent(new Event('answer-received'))

      expect(textarea.value).toEqual('')
    })

    it('hides the character count hint', () => {
      // Type in enough characters to make the hint show on screen
      textarea.value = 'A'.repeat(280)
      textarea.dispatchEvent(new Event('keyup'))
      expect(form.innerHTML).toContain('You have 20 characters remaining')

      div.dispatchEvent(new Event('answer-received'))

      expect(form.innerHTML).not.toContain('You have 20 characters remaining')
    })
  })
})

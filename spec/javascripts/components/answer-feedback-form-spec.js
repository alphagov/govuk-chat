describe('AnswerFeedbackForm component', () => {
  'use strict'

  let module, form, buttonGroup, feedbackSubmittedDiv, hideButton, event, fetchSpy

  beforeEach(function () {
    form = document.createElement('form')
    form.action = '/feedback'
    form.innerHTML = `
      <div class="js-button-group"></div>
      <div class="js-feedback-submitted">
        <button class="js-hide-control"></button>
      </div>
    `
    document.body.appendChild(form)
    buttonGroup = form.querySelector('.js-button-group')
    feedbackSubmittedDiv = form.querySelector('.js-feedback-submitted')
    hideButton = feedbackSubmittedDiv.querySelector('.js-hide-control')
    event = new Event('submit')
    event.submitter = { name: 'create_answer_feedback[useful]', value: 'true' }
    module = new window.GOVUK.Modules.AnswerFeedbackForm(form)
  })

  afterEach(function () {
    document.body.removeChild(form)
  })

  describe('when receiving a submit event', () => {
    beforeEach(() => {
      module.init()

      fetchSpy = spyOn(window, 'fetch')
    })

    it('prevents the event from performing default behaviour', () => {
      const preventDefaultSpy = spyOn(event, 'preventDefault')
      form.dispatchEvent(event)

      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('hides the feedback form button group', () => {
      form.dispatchEvent(event)
      expect(buttonGroup.hidden).toEqual(true)
    })

    it('shows the feedback submitted div when the user provides feedback', () => {
      form.dispatchEvent(event)

      expect(feedbackSubmittedDiv.hidden).toEqual(false)
    })

    it('submits a JSON fetch request to the action of the form', () => {
      form.dispatchEvent(event)

      const formData = new FormData()
      formData.append('create_answer_feedback[useful]', event.submitter.value)

      expect(fetchSpy).toHaveBeenCalledWith(form.action, jasmine.objectContaining({
        method: 'POST',
        body: formData,
        headers: {
          Accept: 'application/json'
        }
      }))
    })

    describe('when the fetch request throws an error', () => {
      beforeEach(() => { fetchSpy.and.throwError(new Error('An error occurred')) })

      it('submits the form', () => {
        const formSubmitSpy = spyOn(form, 'submit')
        form.dispatchEvent(event)

        expect(formSubmitSpy).toHaveBeenCalled()
      })
    })
  })

  describe('when feedback has been submitted', () => {
    beforeEach(() => {
      module.init()
      fetchSpy = spyOn(window, 'fetch')
      form.dispatchEvent(event)
    })

    it('adds an event listener to the hide button which prevents default', () => {
      const onClickEvent = new Event('click')
      const preventDefaultSpy = spyOn(onClickEvent, 'preventDefault')

      hideButton.dispatchEvent(onClickEvent)

      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('hides the component when the hide button is clicked', () => {
      hideButton.dispatchEvent(new Event('click'))
      expect(form.hidden).toEqual(true)
    })
  })
})

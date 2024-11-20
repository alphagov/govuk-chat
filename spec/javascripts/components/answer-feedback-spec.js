describe('AnswerFeedback component', () => {
  'use strict'

  let module, rootDiv, form, feedbackSubmittedContainer, event, fetchSpy

  beforeEach(function () {
    rootDiv = document.createElement('div')
    rootDiv.innerHTML = `
      <form class="js-form" action="/feedback">
      </form>
      <div class="js-feedback-submitted">
      </div>
    `
    document.body.appendChild(rootDiv)
    form = rootDiv.querySelector('.js-form')
    feedbackSubmittedContainer = rootDiv.querySelector('.js-feedback-submitted')
    event = new Event('submit')
    event.submitter = { name: 'create_answer_feedback[useful]', value: 'true' }
    module = new window.GOVUK.Modules.AnswerFeedback(rootDiv)
  })

  afterEach(function () {
    document.body.removeChild(rootDiv)
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

    it('hides the form', () => {
      form.dispatchEvent(event)
      expect(form.hidden).toEqual(true)
    })

    it('shows the feedback submitted div when the user provides feedback', () => {
      form.dispatchEvent(event)

      expect(feedbackSubmittedContainer.hidden).toEqual(false)
      expect(feedbackSubmittedContainer.ownerDocument.activeElement === feedbackSubmittedContainer)
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
})

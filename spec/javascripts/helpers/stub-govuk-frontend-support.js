beforeAll(function () {
  // modules that rely on GOV.UK Frontend expect this class to be present on
  // the body element. For us we'd not be loading the JS without this class
  // so it's somewhat moot - however we need this to prevent the GOV.UK Frontend
  // JS erroring when a module is called directly.
  document.body.classList.add('govuk-frontend-supported')
})

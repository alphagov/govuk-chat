window.asymmetricMatchers = window.asymmetricMatchers || {}

window.asymmetricMatchers.matchElementBySelector = selector => {
  return {
    asymmetricMatch: element => element.matches(selector),
    jasmineToString: () => `<matchElementBySelector:${selector}>`
  }
}

// JS in this file is served to both modern and legacy browsers

// These govuk_publishing_components files do not work in a script type=module
// setting and thus need to be loaded
//= require govuk_publishing_components/dependencies
//= require govuk_publishing_components/lib

//= require govuk_publishing_components/components/cookie-banner

// In browsers that do not support ES6 modules
if (!('noModule' in window.HTMLScriptElement.prototype)) {
  // prevent other modules from running by stopping event propagation
  document.addEventListener(
    'DOMContentLoaded',
    function (e) {
      e.stopImmediatePropagation()
      e.stopPropagation()
    },
    true // use capture - this allows this handler to be called before bubbling handlers
  )
}

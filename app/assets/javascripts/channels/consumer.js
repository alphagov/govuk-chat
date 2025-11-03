//= require actioncable
//= require_self

window.GOVUK = window.GOVUK || {}
const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
window.GOVUK.consumer = ActionCable.createConsumer(`${protocol}//${window.location.host}/cable`);

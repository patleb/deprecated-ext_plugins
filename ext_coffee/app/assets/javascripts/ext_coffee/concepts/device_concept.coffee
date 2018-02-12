# https://codeburst.io/the-only-way-to-detect-touch-with-javascript-7791a3346685

class Js.DeviceConcept
  global: true

  ready_once: =>
    @touched = false
    window.addEventListener('touchstart', @on_first_touch, false)

  on_first_touch: =>
    @touched = true
    window.removeEventListener('touchstart', @on_first_touch, false);

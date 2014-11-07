/* globals QUnit */

export default function setupQUnit(assertion, _qunitGlobal) {
  var qunitGlobal = QUnit;

  if (_qunitGlobal) {
    qunitGlobal = _qunitGlobal;
  }

  var originalModule = qunitGlobal.module;

  qunitGlobal.module = function(name, _originalOptions) {
    var originalOptions = _originalOptions || {};

    var options = {
      setup: function() {
        var originalCallback = originalOptions.setup || function() { };

        assertion.reset();
        assertion.inject();

        originalCallback();
      },

      teardown: function() {
        var originalCallback = originalOptions.teardown || function() { };

        originalCallback();

        assertion.assert();
        assertion.restore();
      }
    };

    return originalModule(name, options);
  };
}

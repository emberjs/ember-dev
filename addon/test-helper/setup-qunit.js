/* globals QUnit */

export default function setupQUnit(assertion, _qunitGlobal) {
  var qunitGlobal = QUnit;

  if (_qunitGlobal) {
    qunitGlobal = _qunitGlobal;
  }

  var originalModule = qunitGlobal.module;

  qunitGlobal.module = function(name, _options) {
    var options = _options || {};
    var originalSetup = options.setup || function() { };
    var originalTeardown = options.teardown || function() { };

    options.setup = function() {
      assertion.reset();
      assertion.inject();

      originalSetup.call(this);
    };

    options.teardown = function() {
      originalTeardown.call(this);

      assertion.assert();
      assertion.restore();
    };

    return originalModule(name, options);
  };
}

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

      originalSetup.apply(this, arguments);
    };

    options.teardown = function(assert) {
      var result = originalTeardown.apply(this, arguments);

      if (result && result.then) {
        var done = assert.async();
        return result.then(function(value) {
          // this is basically the worst thing ever, but
          // by default Ember automatically wraps all RSVP
          // promises in a run-loop.  THAT IS WONDERFUL!!!
          //
          // However, it is not so wonderful when you are actually
          // trying to confirm that you are not incorrectly in a
          // run-loop after the tests are all done. :(
          //
          // This works by forcing the actual assertions to happen
          // shortly after the promise resolves (and uses `assert.async`
          // to ensure QUnit doesn't move on to the next test)
          setTimeout(function() {
            assertion.assert();
            assertion.restore();
            done();
          }, 0);

          return value;
        })
        .catch(function(reason) {
          done();
          throw reason;
        });
      } else {
        assertion.assert();
        assertion.restore();
        return result;
      }
    };

    return originalModule(name, options);
  };
}

(function() {
  window.EmberDev = window.EmberDev || {};

  // hack qunit to not suck for Ember objects
  var originalTypeof = QUnit.jsDump.typeOf;

  QUnit.jsDump.typeOf = function(obj) {
    if (Ember && Ember.Object && Ember.Object.detectInstance(obj)) {
      return "emberObject";
    }

    return originalTypeof.call(this, obj);
  };

  QUnit.jsDump.parsers.emberObject = function(obj) {
    return obj.toString();
  };

  var originalModule = module;
  module = function(name, origOpts) {
    var opts = {};
    if (origOpts && origOpts.setup) { opts.setup = origOpts.setup; }
    opts.teardown = function() {
      if (origOpts && origOpts.teardown) { origOpts.teardown(); }

      if (Ember && Ember.run) {
        if (Ember.run.currentRunLoop) {
          ok(false, "Should not be in a run loop at end of test");
          while (Ember.run.currentRunLoop) {
            Ember.run.end();
          }
        }
        if (Ember.run.hasScheduledTimers()) {
          // Use `ok` so we get full description.
          // Gate inside of `if` so that we don't mess up `expects` counts
          ok(false, "Ember run should not have scheduled timers at end of test");
          Ember.run.cancelTimers();
        }
      }

      if (EmberDev.afterEach) {
        EmberDev.afterEach();
      }
    };
    return originalModule(name, opts);
  };

  // Tests should time out after 5 seconds
  QUnit.config.testTimeout = 5000;

  // Handle JSHint
  QUnit.config.urlConfig.push('nojshint');

  EmberDev.jsHint = !QUnit.urlParams.nojshint;

  EmberDev.jsHintReporter = function (file, errors) {
    if (!errors) { return ''; }

    var len = errors.length,
        str = '',
        error, idx;

    if (len === 0) { return ''; }

    for (idx=0; idx<len; idx++) {
      error = errors[idx];
      str += file  + ': line ' + error.line + ', col ' +
          error.character + ', ' + error.reason + '\n';
    }

    return str + "\n" + len + ' error' + ((len === 1) ? '' : 's');
  };
})();

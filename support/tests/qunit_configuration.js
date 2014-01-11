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

  // Hide passed tests by default
  QUnit.config.hidepassed = true;

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

  // A light class for stubbing
  //
  function MethodCallExpectation(target, property){
    this.target = target;
    this.property = property;
  };

  MethodCallExpectation.prototype = {
    handleCall: function(){
      this.sawCall = true;
      return this.originalMethod.apply(this.target, arguments);
    },
    stubMethod: function(fn){
      var context = this;
      this.originalMethod = this.target[this.property];
      this.target[this.property] = function(){
        return context.handleCall.apply(context, arguments);
      };
    },
    restoreMethod: function(){
      this.target[this.property] = this.originalMethod;
    },
    runWithStub: function(fn){
      try {
        this.stubMethod();
        fn();
      } finally {
        this.restoreMethod();
      }
    },
    assert: function(fn) {
      this.runWithStub();
      ok(this.sawCall, "Expected "+this.property+" to be called.");
    }
  };

  function AssertExpectation(message){
    MethodCallExpectation.call(this, Ember, 'assert');
    this.expectedMessage = message;
  };
  AssertExpectation.Error = function(){};
  AssertExpectation.prototype = Object.create(MethodCallExpectation.prototype);
  AssertExpectation.prototype.handleCall = function(message, test){
    this.sawCall = true;
    if (test) return; // Only get message for failures
    this.actualMessage = message;
    // Halt execution
    throw new AssertExpectation.Error();
  };
  AssertExpectation.prototype.assert = function(fn){
    try {
      this.runWithStub(fn);
    } catch (e) {
      if (!(e instanceof AssertExpectation.Error))
        throw e;
    }

    // Run assertions in an order that is useful when debugging a test failure.
    //
    if (!this.sawCall) {
      ok(false, "Expected Ember.assert to be called (Not called with any value).");
    } else if (!this.actualMessage) {
      ok(false, 'Expected a failing Ember.assert (Ember.assert called, but without a failing test).');
    } else {
      if (this.expectedMessage) {
        if (this.expectedMessage instanceof RegExp) {
          ok(this.expectedMessage.test(this.actualMessage), "Expected failing Ember.assert: '" + this.expectedMessage + "', but got '" + this.actualMessage + "'.");
        } else {
          equal(this.actualMessage, this.expectedMessage, "Expected failing Ember.assert: '" + this.expectedMessage + "', but got '" + this.actualMessage + "'.");
        }
      } else {
        // Positive assertion that assert was called
        ok(true, 'Expected a failing Ember.assert.');
      }
    }
  };

  window.expectAssertion = function expectAssertion(fn, message){
    (new AssertExpectation(message)).assert(fn);
  };

  function DeprecateExpectation(message){
    MethodCallExpectation.call(this, Ember, 'deprecate');
    this.expectedMessage = message;
  };
  DeprecateExpectation.prototype = Object.create(MethodCallExpectation.prototype);
  DeprecateExpectation.prototype.handleCall = function(message, test){
    this.sawCall = true;
    if (arguments.length === 1 || !test) {
      this.actualMessage = message;
    }
  };
  DeprecateExpectation.prototype.assert = function(fn){
    this.runWithStub(fn);

    // Run assertions in an order that is useful when debugging a test failure.
    //
    if (!this.sawCall) {
      ok(false, "Expected Ember.deprecate to be called.");
    } else if (!this.actualMessage) {
      ok(false, 'Expected a failing Ember.deprecate (Ember.deprecate called, but without a failing test).');
    } else {
      if (this.expectedMessage) {
        equal(this.actualMessage, this.expectedMessage, 'Expected failing Ember.deprecate: "'+this.expectedMessage+'", but got "'+this.actualMessage+'".');
      } else {
        // Positive assertion that deprecate was called
        ok(true, "Expected a failing Ember.deprecate.");
      }
    }
  };

  window.expectDeprecation = function expectAssertion(fn, message){
    (new DeprecateExpectation(message)).assert(fn);
  };
})();

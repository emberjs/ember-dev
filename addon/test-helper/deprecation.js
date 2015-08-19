import MethodCallTracker from './method-call-tracker';
import { callWithStub } from './utils';

var DeprecationAssert = function(env) {
  this.env = env;
};

DeprecationAssert.prototype = {
  reset() {
    if (this.tracker) {
      this.tracker.restoreMethod();
    }

    this.tracker = null;
  },

  inject() {
    // Expects no deprecation to happen within a function, or if no function is
    // passed, from the time of calling until the end of the test.
    //
    // expectNoDeprecation(function() {
    //   fancyNewThing();
    // });
    //
    // expectNoDeprecation();
    // Ember.deprecate("Old And Busted");
    //
    let expectNoDeprecation = (func) => {
      if (typeof func !== 'function') {
        func = null;
      }

      this.runExpectation(func, (tracker) => {
        if (tracker.isExpectingCalls()) {
          throw new Error("expectNoDeprecation was called after expectDeprecation was called!");
        }

        tracker.expectNoCalls();
      });
    };

    // Expect a deprecation to happen within a function, or if no function
    // is pass, from the time of calling until the end of the test. Can be called
    // multiple times to assert deprecations with different specific messages
    // were fired.
    //
    // expectDeprecation(function() {
    //   Ember.deprecate("Old And Busted");
    // }, /* optionalStringOrRegex */);
    //
    // expectDeprecation(/* optionalStringOrRegex */);
    // Ember.deprecate("Old And Busted");
    //
    let expectDeprecation = (func, message) => {
      if (typeof func !== 'function') {
        message = func;
        func = null;
      }

      this.runExpectation(func, (tracker) => {
        if (tracker.isExpectingNoCalls()) {
          throw new Error("expectDeprecation was called after expectNoDeprecation was called!");
        }

        tracker.expectCall(message);
      });
    };

    let ignoreDeprecation = (func) => {
      callWithStub(this.env, 'deprecate', func);
    };

    window.expectNoDeprecation = expectNoDeprecation;
    window.expectDeprecation = expectDeprecation;
    window.ignoreDeprecation = ignoreDeprecation;
  },

  // Forces an assert the deprecations occurred, and resets the globals
  // storing asserts for the next run.
  //
  // expectNoDeprecation(/Old/);
  // setTimeout(function() {
  //   Ember.deprecate("Old And Busted");
  //   assertDeprecation();
  // });
  //
  // assertDeprecation is called after each test run to catch any expectations
  // without explicit asserts.
  //
  assert() {
    if (this.tracker) {
      this.tracker.assert();
    }
  },

  restore() {
    this.reset();
    window.expectDeprecation = null;
    window.expectNoDeprecation = null;
    window.ignoreDeprecation = null;
  },

  runExpectation(func, callback)  {
    let originalTracker;

    // When helpers are passed a callback, they get a new tracker context
    if (func) {
      originalTracker = this.tracker;
      this.tracker = null;
    }

    if (!this.tracker) {
      this.tracker = new MethodCallTracker(this.env, 'deprecate');
    }

    callback(this.tracker);

    // Once the given callback is invoked, the pending assertions should be
    // flushed immediately
    if (func) {
      func();
      this.assert();
      this.reset();

      this.tracker = originalTracker;
    }
  }
};

export default DeprecationAssert;

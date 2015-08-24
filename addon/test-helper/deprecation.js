/* globals QUnit */

import { callWithStub, checkTest } from './utils';

var NONE = function() {};

var DeprecationAssert = function(env){
  this.env = env;
  this.reset();
};

DeprecationAssert.prototype = {

  reset() {
    this.expecteds = null;
    this.actuals = null;
    this.originalDeprecate = null;
  },

  stubEmber() {
    if (!this.originalDeprecate) {
      this.originalDeprecate = this.env.getDebugFunction('deprecate');
    }

    this.env.setDebugFunction('deprecate', (message, test) => {
      var resultOfTest = checkTest(test);
      var shouldDeprecate = !resultOfTest;

      this.actuals = this.actuals || [];
      if (shouldDeprecate) {
        this.actuals.push([message, resultOfTest]);
      }
    });
  },

  inject() {
    // Expects no deprecation to happen from the time of calling until
    // the end of the test.
    //
    // expectNoDeprecation(/* optionalStringOrRegex */);
    // Ember.deprecate("Old And Busted");
    //
    let expectNoDeprecation = () => {
      if (this.expecteds != null && typeof this.expecteds === 'object') {
        throw new Error("expectNoDeprecation was called after expectDeprecation was called!");
      }
      this.stubEmber();
      this.expecteds = NONE;
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
      var originalExpecteds, originalActuals;

      if (this.expecteds === NONE) {
        throw new Error("expectDeprecation was called after expectNoDeprecation was called!");
      }
      this.stubEmber();
      this.expecteds = this.expecteds || [];
      if (func && typeof func !== 'function') {
        // func is a message
        this.expecteds.push(func);
      } else {
        originalExpecteds = this.expecteds.slice();
        originalActuals = this.actuals ? this.actuals.slice() : this.actuals;

        this.expecteds.push(message || /.*/);

        if (func) {
          func();
          this.assert();

          this.expecteds = originalExpecteds;
          this.actuals = originalActuals;
        }
      }
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
    var expecteds = this.expecteds || [],
        actuals   = this.actuals || [];
    var o, i;

    if (expecteds !== NONE && expecteds.length === 0 && actuals.length === 0) {
      return;
    }

    if (this.env.runningProdBuild){
      QUnit.ok(true, 'deprecations disabled in production builds.');
      return;
    }

    if (expecteds === NONE) {
      var actualMessages = [];
      for (i=0;i<actuals.length;i++) {
        actualMessages.push(actuals[i][0]);
      }
      QUnit.ok(actuals.length === 0, "Expected no deprecation calls, got "+actuals.length+": "+actualMessages.join(', '));
      return;
    }

    var expected, actual, match;

    for (o=0;o < expecteds.length; o++) {
      expected = expecteds[o];
      for (i=0;i < actuals.length; i++) {
        actual = actuals[i];
        if (!actual[1]) {
          if (expected instanceof RegExp) {
            if (expected.test(actual[0])) {
              match = actual;
              break;
            }
          } else {
            if (expected === actual[0]) {
              match = actual;
              break;
            }
          }
        }
      }

      if (!actual) {
        QUnit.ok(false, "Recieved no deprecate calls at all, expecting: "+expected);
      } else if (match && !match[1]) {
        QUnit.ok(true, "Recieved failing deprecation with message: "+match[0]);
      } else if (match && match[1]) {
        QUnit.ok(false, "Expected failing deprecation, got succeeding with message: "+match[0]);
      } else if (actual[1]) {
        QUnit.ok(false, "Did not receive failing deprecation matching '"+expected+"', last was success with '"+actual[0]+"'");
      } else if (!actual[1]) {
        QUnit.ok(false, "Did not receive failing deprecation matching '"+expected+"', last was failure with '"+actual[0]+"'");
      }
    }
  },

  restore() {
    if (this.originalDeprecate) {
      this.env.setDebugFunction('deprecate', this.originalDeprecate);
    }

    window.expectNoDeprecation = null;
    window.expectDeprecation = null;
    window.ignoreDeprecation = null;
  }

};

export default DeprecationAssert;

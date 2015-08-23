/* globals QUnit */

import MethodCallExpectation from "./method-call-expectation";

var NONE = function(){};

var DeprecationAssert = function(env){
  this.env = env;

  this.reset();
};

DeprecationAssert.prototype = {

  reset: function(){
    this.expecteds = null;
    this.actuals = null;
  },

  stubEmber: function(){
    if (!this._previousEmberDeprecate) {
      this._previousEmberDeprecate = this.env.getDebugFunction('deprecate');
    }

    var assertion = this;
    this.env.setDebugFunction('deprecate', function(msg, test) {
      var resultOfTest = typeof test === 'function' ? test() : test;
      var shouldDeprecate = !resultOfTest;

      assertion.actuals = assertion.actuals || [];
      if (shouldDeprecate) {
        assertion.actuals.push([msg, resultOfTest]);
      }
    });
  },

  inject: function(){
    var assertion = this;

    // Expects no deprecation to happen from the time of calling until
    // the end of the test.
    //
    // expectNoDeprecation(/* optionalStringOrRegex */);
    // Ember.deprecate("Old And Busted");
    //
    window.expectNoDeprecation = function() {
      if (assertion.expecteds != null && typeof assertion.expecteds === 'object') {
        throw new Error("expectNoDeprecation was called after expectDeprecation was called!");
      }
      assertion.stubEmber();
      assertion.expecteds = NONE;
    };

    // Expect a deprecation to happen within a function, or if no function
    // is pass, from the time of calling until the end of the test. Can be called
    // multiple times to assert deprecations with different specific messages
    // were fired.
    //
    // expectDeprecation(function(){
    //   Ember.deprecate("Old And Busted");
    // }, /* optionalStringOrRegex */);
    //
    // expectDeprecation(/* optionalStringOrRegex */);
    // Ember.deprecate("Old And Busted");
    //
    window.expectDeprecation = function(fn, message) {
      var originalExpecteds, originalActuals;

      if (assertion.expecteds === NONE) {
        throw new Error("expectDeprecation was called after expectNoDeprecation was called!");
      }
      assertion.stubEmber();
      assertion.expecteds = assertion.expecteds || [];
      if (fn && typeof fn !== 'function') {
        // fn is a message
        assertion.expecteds.push(fn);
      } else {
        originalExpecteds = assertion.expecteds.slice();
        originalActuals = assertion.actuals ? assertion.actuals.slice() : assertion.actuals;

        assertion.expecteds.push(message || /.*/);

        if (fn) {
          fn();
          assertion.assert();

          assertion.expecteds = originalExpecteds;
          assertion.actuals = originalActuals;
        }
      }
    };

    window.ignoreDeprecation = function ignoreDeprecation(fn){
      var stubber = new MethodCallExpectation(assertion.env.Ember, 'deprecate'),
          noop = function(){};

      stubber.runWithStub(fn, noop);
    };

  },

  // Forces an assert the deprecations occurred, and resets the globals
  // storing asserts for the next run.
  //
  // expectNoDeprecation(/Old/);
  // setTimeout(function(){
  //   Ember.deprecate("Old And Busted");
  //   assertDeprecation();
  // });
  //
  // assertDeprecation is called after each test run to catch any expectations
  // without explicit asserts.
  //
  assert: function(){
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

  restore: function(){
    if (this._previousEmberDeprecate) {
      this.env.setDebugFunction('deprecate', this._previousEmberDeprecate);
      this._previousEmberDeprecate = null;
    }
    window.expectNoDeprecation = null;
  }

};

export default DeprecationAssert;

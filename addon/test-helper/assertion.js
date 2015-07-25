/* globals QUnit */

import MethodCallExpectation from "./method-call-expectation";

function AssertExpectation(Ember, message){
  MethodCallExpectation.call(this, Ember, 'assert');
  this.expectedMessage = message;
}
AssertExpectation.Error = function(){};
AssertExpectation.prototype = Object.create(MethodCallExpectation.prototype);
AssertExpectation.prototype.handleCall = function(message, test){
  var noAssertion = typeof test === 'function' ? test() : test;

  this.sawCall = true;

  if (noAssertion) {
    return;
  }

  this.actualMessage = message;
  // Halt execution
  throw new AssertExpectation.Error();
};
AssertExpectation.prototype.assert = function(fn){
  try {
    this.runWithStub(fn);
  } catch (e) {
    if (!(e instanceof AssertExpectation.Error)) {
      throw e;
    }
  }

  // Run assertions in an order that is useful when debugging a test failure.
  //
  if (!this.sawCall) {
    QUnit.ok(false, "Expected Ember.assert to be called (Not called with any value).");
  } else if (!this.actualMessage) {
    QUnit.ok(false, 'Expected a failing Ember.assert (Ember.assert called, but without a failing test).');
  } else {
    if (this.expectedMessage) {
      if (this.expectedMessage instanceof RegExp) {
        QUnit.ok(this.expectedMessage.test(this.actualMessage), "Expected failing Ember.assert: '" + this.expectedMessage + "', but got '" + this.actualMessage + "'.");
      } else {
        QUnit.equal(this.actualMessage, this.expectedMessage, "Expected failing Ember.assert: '" + this.expectedMessage + "', but got '" + this.actualMessage + "'.");
      }
    } else {
      // Positive assertion that assert was called
      QUnit.ok(true, 'Expected a failing Ember.assert.');
    }
  }
};

var AssertionAssert = function(env){
  this.env = env;
};

AssertionAssert.prototype = {

  reset: function(){
  },

  inject: function(){

    var assertion = this;

    // Looks for an exception raised within the fn.
    //
    // expectAssertion(function(){
    //   Ember.assert("Homie don't roll like that");
    // } /* , optionalMessageStringOrRegex */);
    //
    window.expectAssertion = function expectAssertion(fn, message){
      if (assertion.env.runningProdBuild){
        QUnit.ok(true, 'Assertions disabled in production builds.');
        return;
      }

      // do not assert as the production builds do not contain Ember.assert
      (new AssertExpectation(assertion.env.Ember, message)).assert(fn);
    };

    window.ignoreAssertion = function ignoreAssertion(fn){
      var stubber = new MethodCallExpectation(assertion.env.Ember, 'assert'),
          noop = function(){};

      stubber.runWithStub(fn, noop);
    };

  },

  assert: function(){
  },

  restore: function(){
    window.expectAssertion = null;
    window.ignoreAssertion = null;
  }

};

export default AssertionAssert;

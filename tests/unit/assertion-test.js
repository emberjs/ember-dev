import Ember from 'ember';
import AssertionAssert from 'ember-dev/test-helper/assertion';
import makeEnv from '../helpers/make-env';

let originalOk;
let originalAssert;
let assertion;

let env = makeEnv();

module('AssertionAssert', {
  beforeEach() {
    originalOk = QUnit.ok;
    originalAssert = env.getDebugFunction('assert');
  },
  afterEach() {
    QUnit.ok = originalOk;
    env.setDebugFunction('assert', originalAssert);

    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('expectAssertion fires when an expected assertion is not called', function(){
  expect(2);

  assertion = new AssertionAssert(env);

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - expectAssertion callback run');
    QUnit.ok = function(isOk) {
      originalOk(!isOk);
    };
  });
});

test('expectAssertion fires when an expected assertion does not pass for boolean values', function(){
  expect(2);

  assertion = new AssertionAssert(env);

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - assertion expectation is called');
    Ember.assert('some assert', false);
  });
});

test('expectAssertion fires when an expected assertion does not pass for functions', function(){
  expect(2);

  assertion = new AssertionAssert(env);

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - assertion expectation is called');
    Ember.assert('some assert', function() {
      return false;
    });
  });
});

test('expectAssertion does not fire when an expected assertion passes for boolean values', function(){
  expect(2);

  assertion = new AssertionAssert(env);

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - assertion expectation is called');
    QUnit.ok = function(isOk){
      originalOk(!isOk);
    };
    Ember.assert('some assert', true);
  });
});

test('expectAssertion does not fire when an expected assertion passes for functions', function(){
  expect(2);

  assertion = new AssertionAssert(env);

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - assertion expectation is called');
    QUnit.ok = function(isOk){
      originalOk(!isOk);
    };
    Ember.assert('some assert', function() {
      return true;
    });
  });
});

test('ignoreAssertion silences assertions', function(){
  expect(1);

  env.setDebugFunction('assert', function() {
    originalOk(false, 'should not call assert');
  });

  assertion = new AssertionAssert(env);

  assertion.inject();
  window.ignoreAssertion(function(){
    ok(true, 'precond - assert callback is run');
    Ember.assert('some assert');
  });
});

/* Pending:
test('expectAssertion with string matcher');
test('expectAssertion with regex matcher');
*/

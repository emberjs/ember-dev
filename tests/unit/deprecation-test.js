import Ember from 'ember';
import DeprecationAssert from 'ember-dev/test-helper/deprecation';
import makeEnv from '../helpers/make-env';

let originalOk;
let originalDeprecate;
let assertion;

let env = makeEnv();

module('DeprecationAssert', {
  beforeEach() {
    originalOk = QUnit.ok;
    originalDeprecate = env.getDebugFunction('deprecate');
  },
  afterEach() {
    QUnit.ok = originalOk;
    env.setDebugFunction('deprecate', originalDeprecate);

    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('Ember.deprecate is restored properly', function() {
  expect(1);

  assertion = new DeprecationAssert(env);

  assertion.inject();
  // Force the method to be stubbed
  window.expectNoDeprecation();
  assertion.restore();

  equal(env.getDebugFunction('deprecate'), originalDeprecate);
});

test('expectDeprecation fires when an expected deprecation is not called', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();
  window.expectDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  assertion.assert();
});

test('expectDeprecation asserts when string does not match exactly', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  window.expectDeprecation('some dep');

  Ember.deprecate('some dep with long desc');

  assertion.assert();
});

test('expectDeprecation does not assert when string matches exactly', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  window.expectDeprecation('some dep');

  Ember.deprecate('some dep');

  assertion.assert();
});

test('expectDeprecation asserts when regex does not match', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  window.expectDeprecation(/some dep/);

  Ember.deprecate('some different dep');

  assertion.assert();
});

test('expectDeprecation does not assert when regex matches', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  window.expectDeprecation(/some dep/);

  Ember.deprecate('some dep with long desc');

  assertion.assert();
});

test('expectDeprecation fires when an expected deprecation does not pass for boolean values', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();
  window.expectDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.deprecate('some dep', true);

  assertion.assert();
});

test('expectDeprecation fires when an expected deprecation does not pass for functions', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();
  window.expectDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.deprecate('some dep', function() {
    return true;
  });

  assertion.assert();
});

test('expectDeprecation fires when an expected deprecation does pass for functions', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();
  window.expectDeprecation();

  QUnit.ok = function(isOk){
    originalOk(isOk);
  };

  Ember.deprecate('some dep', function() {
    return false;
  });

  assertion.assert();
});


test('expectDeprecation uses the provided callback', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  window.expectDeprecation(function() {
    Ember.deprecate('some dep');
  });
});

test('expectDeprecation asserts when given a callback and string does not match exactly', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  window.expectDeprecation(function() {
    Ember.deprecate('some dep with long desc');
  }, 'some dep');
});

test('expectDeprecation does not assert when given a callback and string matches exactly', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  window.expectDeprecation(function() {
    Ember.deprecate('some dep');
  }, 'some dep');
});

test('expectDeprecation asserts when given a callback and regex does not match', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  window.expectDeprecation(function() {
    Ember.deprecate('some different dep');
  }, /some dep/);
});

test('expectDeprecation does not assert when given a callback and regex matches', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  window.expectDeprecation(function() {
    Ember.deprecate('some dep with long desc');
  }, /some dep/);
});

test('expectDeprecation makes a single assertion regardless of deprecation in production builds', function(){
  expect(2);

  assertion = new DeprecationAssert(makeEnv({ runningProdBuild: true }));

  assertion.inject();

  window.expectDeprecation(function() {
    ok(true, 'callback was called in production');
  });

  assertion.assert();
});

test('expectDeprecation with a provided callback only asserts once', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  window.expectDeprecation(function() {
    Ember.deprecate('some dep');
  }, 'some dep');

  assertion.assert();
});

test('expectDeprecation with callback in production does not assert twice', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv({ runningProdBuild: true }));

  assertion.inject();

  window.expectDeprecation(function() {
    Ember.deprecate('some dep');
  });

  assertion.assert();
});

test('expectNoDeprecation fires when an un-expected deprecation calls', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();
  window.expectNoDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.deprecate('some dep');

  assertion.assert();
});

test('expectNoDeprecation fires when a deprecation does not pass for functions', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();
  window.expectNoDeprecation();

  QUnit.ok = function(isOk){
    originalOk(isOk);
  };

  Ember.deprecate('some dep', function() {
    return true;
  });

  assertion.assert();
});

test('expectNoDeprecation makes an assertion in production mode', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv({ runningProdBuild: true }));

  assertion.reset();
  assertion.inject();

  window.expectNoDeprecation();

  assertion.assert();
});

test('expectNoDeprecation ignores a deprecation with an argument invalidating it', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();
  window.expectNoDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.deprecate('some dep', false);

  assertion.assert();
});

test('expectNoDeprecation uses the provided callback', function(){
  expect(1);

  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  window.expectNoDeprecation(function() {
    Ember.deprecate('some dep');
  });
});

test('ignoreDeprecation silences deprecations', function(){
  expect(1);

  let env = makeEnv();
  env.setDebugFunction('deprecate', function() {
    originalOk(false, 'should not call deprecate');
  });

  assertion = new DeprecationAssert(env);

  assertion.inject();
  window.ignoreDeprecation(function(){
    ok(true, 'precond - deprecation callback is run');
    Ember.deprecate('some dep');
  });
});

test('using expectNoDeprecation and expectDeprecation together throws an error', function() {
  assertion = new DeprecationAssert(makeEnv());

  assertion.inject();

  try {
    window.expectNoDeprecation();
    window.expectDeprecation();
  } catch(error) {
    equal(error.message, 'expectDeprecation was called after expectNoDeprecation was called!');
  }

  assertion.reset();

  try {
    window.expectDeprecation();
    window.expectNoDeprecation();
  } catch(error) {
    equal(error.message, 'expectNoDeprecation was called after expectDeprecation was called!');
  }
});

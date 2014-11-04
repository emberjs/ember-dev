import DeprecationAssert from 'ember-dev/test-helper/deprecation';

var originalOk = QUnit.ok;
var assertion;

module('DeprecationAssert', {
  teardown: function(){
    QUnit.ok = originalOk;
    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('expectDeprecation fires when an expected deprecation is not called', function(){
  expect(1);

  var Ember = {};
  assertion = new DeprecationAssert({Ember: Ember});

  assertion.inject();
  window.expectDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  assertion.assert();
});

test('expectDeprecation fires when an expected deprecation does not pass', function(){
  expect(1);

  var Ember = { deprecate: function(){} };
  assertion = new DeprecationAssert({Ember: Ember});

  assertion.inject();
  window.expectDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.deprecate('some dep', true);

  assertion.assert();
});

test('expectNoDeprecation fires when an un-expected deprecation calls', function(){
  expect(1);

  var Ember = { deprecate: function(){} };
  assertion = new DeprecationAssert({Ember: Ember});

  assertion.inject();
  window.expectNoDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.deprecate('some dep');

  assertion.assert();
});

test('expectNoDeprecation ignores a deprecation with an argument invalidating it', function(){
  expect(1);

  var Ember = { deprecate: function(){} };
  assertion = new DeprecationAssert({Ember: Ember});

  assertion.inject();
  window.expectNoDeprecation();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.deprecate('some dep', false);

  assertion.assert();
});

test('ignoreDeprecation silences deprecations', function(){
  expect(1);

  var Ember = { deprecate: function(){ originalOk(false, 'should not call deprecate'); } };
  assertion = new DeprecationAssert({Ember: Ember});

  assertion.inject();
  window.ignoreDeprecation(function(){
    ok(true, 'precond - deprecation callback is run');
    Ember.deprecate('some dep');
  });
});

/* Pending:
test('expect no deprecation with regex matcher');
test('expect no deprecation with string matcher');
test('expect deprecation with regex matcher');
test('expect deprecation with string matcher');
test('expect deprecation with block form');
test('expect deprecation with block form and string matcher');
test('expect deprecation with block form and regex matcher');
*/

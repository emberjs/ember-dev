import AssertionAssert from 'ember-dev/test-helper/assertion';

var originalOk = QUnit.ok;
var assertion;

module('AssertionAssert', {
  teardown: function(){
    QUnit.ok = originalOk;
    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('expectAssertion fires when an expected assertion is not called', function(){
  expect(2);

  var Ember = {};
  assertion = new AssertionAssert({Ember: Ember});

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - expectAssertion callback run');
    QUnit.ok = function(isOk) {
      originalOk(!isOk);
    };
  });
});

test('expectAssertion fires when an expected assertion does not pass', function(){
  expect(2);

  var Ember = { assert: function(){} };
  assertion = new AssertionAssert({Ember: Ember});

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - assertion expectation is called');
    QUnit.ok = function(isOk){
      originalOk(isOk);
    };
    Ember.assert('some assert', false);
  });
});

test('expectAssertion does not fire when an expected assertion passes', function(){
  expect(2);

  var Ember = { assert: function(){} };
  assertion = new AssertionAssert({Ember: Ember});

  assertion.inject();
  window.expectAssertion(function(){
    originalOk(true, 'precond - assertion expectation is called');
    QUnit.ok = function(isOk){
      originalOk(!isOk);
    };
    Ember.assert('some assert', true);
  });
});

test('ignoreAssertion silences assertions', function(){
  expect(1);

  var Ember = { assert: function(){ originalOk(false, 'should not call assert'); } };
  assertion = new AssertionAssert({Ember: Ember});

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

import { buildCompositeAssert } from 'ember-dev/test-helper/utils';

var resetCount, injectCount, assertCount, restoreCount;
var Composite, instance, Ember;

function generateAssertion() {
  function A() {}
  A.prototype = {
    reset: function() { resetCount++; },
    inject: function() { injectCount++; },
    assert: function() { assertCount++; },
    restore: function() { restoreCount++; }
  };

  return A;
}

module('buildCompositeAssert', {
  setup: function() {
    Ember = {};

    resetCount = 0;
    injectCount = 0;
    assertCount = 0;
    restoreCount = 0;

    Composite = buildCompositeAssert([
      generateAssertion(),
      generateAssertion(),
      generateAssertion()
    ]);

    instance = new Composite(Ember, false);
  }
});

test('calls reset on all assertions added', function() {
  instance.reset();

  equal(resetCount, 3);
});

test('calls inject on all assertions added', function() {
  instance.inject();

  equal(injectCount, 3);
});

test('calls assert on all assertions added', function() {
  instance.assert();

  equal(assertCount, 3);
});

test('calls restore on all assertions added', function() {
  instance.restore();

  equal(restoreCount, 3);
});

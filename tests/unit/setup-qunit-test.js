import setupQUnit from 'ember-dev/test-helper/setup-qunit';

var fakeQUnit, actualName, actualOptions, assertion;
var resetCount, injectCount, assertCount, restoreCount;

var modules;
function generateFakeQUnit() {
  return {
    module: function(name, options) {
      modules[name] = options;
    }
  };
}


function generateAssertion() {
  return {
    reset: function() { resetCount++; },
    inject: function() { injectCount++; },
    assert: function() { assertCount++; },
    restore: function() { restoreCount++; }
  };
}

function commonSetup() {
  modules = {};

  resetCount = 0;
  injectCount = 0;
  assertCount = 0;
  restoreCount = 0;

  assertion = generateAssertion();
  fakeQUnit = generateFakeQUnit();
  setupQUnit(assertion, fakeQUnit);
}

module('setupQUnit -- without options', {
  setup: commonSetup
});

test('it does not blow up without options', function() {
  fakeQUnit.module('something');

  var module = modules['something'];

  ok(module, 'module is found');
  ok(typeof module.setup === 'function', 'setup function was added');
  ok(typeof module.teardown === 'function', 'teardown function was added');
});

test('setup invokes reset + inject on assertion', function() {
  fakeQUnit.module('something');

  var module = modules['something'];

  module.setup();
  equal(resetCount, 1, 'called reset on assertion');
  equal(injectCount, 1, 'called inject on assertion');
});

test('teardown invokes assert + restore on assertion', function() {
  fakeQUnit.module('something');

  var module = modules['something'];

  module.teardown();
  equal(assertCount, 1, 'called assert on assertion');
  equal(restoreCount, 1, 'called restore on assertion');
});

module('setupQUnit -- with setup', {
  setup: commonSetup
});

test('setup invokes reset + inject + custom setup', function() {
  var setupCalled;

  fakeQUnit.module('something', {
    setup: function() { setupCalled = true; }
  });

  var module = modules['something'];

  module.setup();

  equal(resetCount, 1, 'called reset on assertion');
  equal(injectCount, 1, 'called inject on assertion');
  equal(setupCalled, true, 'called custom setup');
});

test('custom setup is invoked after assetions are setup', function() {
  expect(2);

  fakeQUnit.module('something', {
    setup: function() {
      equal(resetCount, 1, 'called reset on assertion');
      equal(injectCount, 1, 'called inject on assertion');
    }
  });

  var module = modules['something'];

  module.setup();
});

test('teardown invokes assert + restore on assertion', function() {
  fakeQUnit.module('something');

  var module = modules['something'];

  module.teardown();
  equal(assertCount, 1, 'called assert on assertion');
  equal(restoreCount, 1, 'called restore on assertion');
});

module('setupQUnit -- with teardown', {
  setup: commonSetup
});

test('setup invokes reset + inject on assertion', function() {
  fakeQUnit.module('something');

  var module = modules['something'];

  module.setup();
  equal(resetCount, 1, 'called reset on assertion');
  equal(injectCount, 1, 'called inject on assertion');
});

test('teardown invokes assert + restore on assertion', function() {
  var teardownCalled;
  fakeQUnit.module('something', {
    teardown: function() { teardownCalled = true; }
  });

  var module = modules['something'];

  module.teardown();
  equal(assertCount, 1, 'called assert on assertion');
  equal(restoreCount, 1, 'called restore on assertion');
  equal(teardownCalled, true, 'called custom teardown');
});

test('custom teardown is invoked before assertions', function() {
  expect(4);

  fakeQUnit.module('something', {
    teardown: function() {
      equal(assertCount, 0, 'called assert on assertion');
      equal(restoreCount, 0, 'called restore on assertion');
    }
  });

  var module = modules['something'];

  module.teardown();
  equal(assertCount, 1, 'called assert on assertion');
  equal(restoreCount, 1, 'called restore on assertion');
});

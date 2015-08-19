import Ember from 'ember';
import WarningAssert from 'ember-dev/test-helper/warning';
import makeEnv from '../helpers/make-env';

let originalOk;
let originalWarn;
let assertion;

let env = makeEnv();

module('WarningAssert', {
  beforeEach() {
    originalOk = QUnit.ok;
    originalWarn = env.getDebugFunction('warn');
  },
  afterEach() {
    QUnit.ok = originalOk;
    env.setDebugFunction('warn', originalWarn);

    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('Ember.warn is restored properly', function() {
  expect(1);

  assertion = new WarningAssert(env);

  assertion.inject();
  // Force the method to be stubbed
  window.expectNoWarning();
  assertion.restore();

  equal(env.getDebugFunction('warn'), originalWarn);
});

test('expectWarning fires when an expected warning is not logged', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.expectWarning();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  assertion.assert();
});

test('expectWarning asserts when string does not match exactly', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk) {
    originalOk(!isOk);
  };

  window.expectWarning('oh');

  Ember.warn('oh noes');

  assertion.assert();
});

test('expectWarning does not assert when string matches exactly', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  window.expectWarning('wat');

  Ember.warn('wat');

  assertion.assert();
});

test('expectWarning asserts when regex does not match', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk) {
    originalOk(!isOk);
  };

  window.expectWarning(/woop woop/);

  Ember.warn('whoops whoops');

  assertion.assert();
});

test('expectWarning does not assert when regex matches', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  window.expectWarning(/woop! woop!/);

  Ember.warn('woop! woop! woop!');

  assertion.assert();
});

test('expectWarning fires when an expected warning does not pass for boolean values', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.expectWarning();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.warn('nooooooo', true);

  assertion.assert();
});

test('expectWarning fires when an expected warning does not pass for functions', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.expectWarning();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.warn('aaaahhhhhh', function() {
    return true;
  });

  assertion.assert();
});

test('expectWarning fires when an expected warning does pass for functions', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.expectWarning();

  QUnit.ok = function(isOk) {
    originalOk(isOk);
  };

  Ember.warn('omgomgomg', function() {
    return false;
  });

  assertion.assert();
});


test('expectWarning uses the provided callback', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  window.expectWarning(function() {
    Ember.warn('right in the ear!');
  });
});

test('expectWarning asserts when given a callback and string does not match exactly', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk) {
    originalOk(!isOk);
  };

  window.expectWarning(function() {
    Ember.warn('ugh');
  }, 'argh');
});

test('expectWarning does not assert when given a callback and string matches exactly', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  window.expectWarning(function() {
    Ember.warn('ugh');
  }, 'ugh');
});

test('expectWarning asserts when given a callback and regex does not match', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk) {
    originalOk(!isOk);
  };

  window.expectWarning(function() {
    Ember.warn('weeeoooweeeooo');
  }, /weeeeeee/);
});

test('expectWarning does not assert when given a callback and regex matches', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  window.expectWarning(function() {
    Ember.warn('weeeoooweeeooo');
  }, /weeeooo/);
});

test('expectWarning makes a single assertion regardless of warning in production builds', function() {
  expect(2);

  assertion = new WarningAssert(makeEnv({ runningProdBuild: true }));

  assertion.inject();

  window.expectWarning(function() {
    ok(true, 'snap, callback was called in production');
  });

  assertion.assert();
});

test('expectWarning with a provided callback only asserts once', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  window.expectWarning(function() {
    Ember.warn('now you done it');
  }, 'now you done it');

  assertion.assert();
});

test('expectWarning with callback in production does not assert twice', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv({ runningProdBuild: true }));

  assertion.inject();

  window.expectWarning(function() {
    Ember.warn('*sigh*');
  });

  assertion.assert();
});

test('expectNoWarning fires when an un-expected warning is logged', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.expectNoWarning();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  Ember.warn('wtf');

  assertion.assert();
});

test('expectNoWarning does not assert when a warning does not pass for functions', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.expectNoWarning();

  QUnit.ok = function(isOk){
    originalOk(isOk);
  };

  Ember.warn('oof', function() {
    return true;
  });

  assertion.assert();
});

test('expectNoWarning makes an assertion in production mode', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv({ runningProdBuild: true }));

  assertion.reset();
  assertion.inject();

  window.expectNoWarning();

  assertion.assert();
});

test('expectNoWarning ignores a warning with an argument invalidating it', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.expectNoWarning();

  QUnit.ok = function(isOk) {
    // this assertion should not fire
    originalOk(!isOk);
  };

  Ember.warn('fuuuuuuuu', false);

  assertion.assert();
});

test('expectNoWarning uses the provided callback', function() {
  expect(1);

  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  window.expectNoWarning(function() {
    Ember.warn('No humor in tests pls');
  });
});

test('ignoreWarning silences warnings', function() {
  expect(1);

  let env = makeEnv();
  env.setDebugFunction('warn', function() {
    originalOk(false, 'oh noes, should not call warn');
  });

  assertion = new WarningAssert(makeEnv());

  assertion.inject();
  window.ignoreWarning(function() {
    ok(true, 'warn callback is run');
    Ember.warn('srsly?');
  });
});

test('using expectNoWarning and expectWarning together throws an error', function() {
  assertion = new WarningAssert(makeEnv());

  assertion.inject();

  try {
    window.expectNoWarning();
    window.expectWarning();
  } catch(error) {
    equal(error.message, 'expectWarning was called after expectNoWarning was called!');
  }

  assertion.reset();

  try {
    window.expectWarning();
    window.expectNoWarning();
  } catch(error) {
    equal(error.message, 'expectNoWarning was called after expectWarning was called!');
  }
});

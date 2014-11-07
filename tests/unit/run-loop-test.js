import Ember from 'ember';
import RunLoopAssertion from 'ember-dev/test-helper/run-loop';

var originalOk = QUnit.ok;
var assertion;

module('RunLoopAssertion', {
  teardown: function(){
    QUnit.ok = originalOk;

    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('fires an assert when in a run loop', function(){
  expect(2);

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  assertion = new RunLoopAssertion({Ember: Ember});

  Ember.run.begin();

  assertion.assert();

  ok(!Ember.run.currentRunLoop, 'ends run loop');
});

test('fires an assert when timers are scheduled', function(){
  expect(2);

  QUnit.ok = function(isOk){
    originalOk(!isOk);
  };

  assertion = new RunLoopAssertion({Ember: Ember});

  Ember.run.later(function() {
    ok(false, 'should not execute');
  });

  assertion.assert();

  ok(!Ember.run.hasScheduledTimers(), 'cancels pending timers');
});

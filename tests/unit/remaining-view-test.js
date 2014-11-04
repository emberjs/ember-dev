import RemainingViewAssert from 'ember-dev/test-helper/remaining-view';

var originalDeepEqual = QUnit.deepEqual;
var assertion;

module('RemainingViewAssert', {
  teardown: function(){
    QUnit.deepEqual = originalDeepEqual;
    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('fires an assert when a view remains', function(){
  expect(1);

  var Ember = {};
  assertion = new RemainingViewAssert({Ember: Ember});

  Ember.View = {'views': {'emberFoo': 'wow'}};

  QUnit.deepEqual = function(a, b){
    QUnit.notDeepEqual(a, b);
  };

  assertion.assert();
});

test('fires no assert without a view', function(){
  expect(0);

  var Ember = {};
  assertion = new RemainingViewAssert({Ember: Ember});

  assertion.assert();
});

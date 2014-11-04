import RemainingTemplateAssert from 'ember-dev/test-helper/remaining-template';

var originalDeepEqual = QUnit.deepEqual;
var assertion;

module('RemainingTemplateAssert', {
  teardown: function(){
    QUnit.deepEqual = originalDeepEqual;
    if (assertion) {
      assertion.restore();
      assertion = null;
    }
  }
});

test('fires an assert when a template remains', function(){
  expect(1);

  var Ember = {};
  assertion = new RemainingTemplateAssert({Ember: Ember});

  Ember.TEMPLATES = {'templateName': 'wow'};

  QUnit.deepEqual = function(a, b){
    QUnit.notDeepEqual(a, b);
  };

  assertion.assert();
});

test('fires no assert without a template', function(){
  expect(0);

  var Ember = {};
  assertion = new RemainingTemplateAssert({Ember: Ember});

  assertion.assert();
});

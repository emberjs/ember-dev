/* globals QUnit */

// A light class for stubbing
//
function MethodCallExpectation(target, property){
  this.target = target;
  this.property = property;
}

MethodCallExpectation.prototype = {
  handleCall: function(){
    this.sawCall = true;
    return this.originalMethod.apply(this.target, arguments);
  },
  stubMethod: function(replacementFunc){
    var context = this,
        property = this.property;

    this.originalMethod = this.target[property];

    if (typeof replacementFunc === 'function') {
      this.target[property] = replacementFunc;
    } else {
      this.target[property] = function(){
        return context.handleCall.apply(context, arguments);
      };
    }
  },
  restoreMethod: function(){
    this.target[this.property] = this.originalMethod;
  },
  runWithStub: function(fn, replacementFunc){
    try {
      this.stubMethod(replacementFunc);
      fn();
    } finally {
      this.restoreMethod();
    }
  },
  assert: function() {
    this.runWithStub.apply(this, arguments);
    QUnit.ok(this.sawCall, "Expected "+this.property+" to be called.");
  }
};

export default MethodCallExpectation;

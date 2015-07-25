function callForEach(prop, func) {
  return function() {
    for (var i=0, l=this[prop].length;i<l;i++) {
      this[prop][i][func]();
    }
  };
}

export function buildCompositeAssert(klasses){
  var Composite = function(emberKlass, runningProdBuild){
    this.asserts = [];
    for (var i=0, l=klasses.length;i<l;i++) {
      this.asserts.push(new klasses[i]({
        Ember: emberKlass,
        runningProdBuild: runningProdBuild
      }));
    }
  };

  Composite.prototype = {
    reset: callForEach('asserts', 'reset'),
    inject: callForEach('asserts', 'inject'),
    assert: callForEach('asserts', 'assert'),
    restore: callForEach('asserts', 'restore')
  };

  return Composite;
}

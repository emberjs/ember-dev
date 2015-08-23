function callForEach(prop, func) {
  return function() {
    for (var i=0, l=this[prop].length;i<l;i++) {
      this[prop][i][func]();
    }
  };
}

export function buildCompositeAssert(assertClasses) {
  function Composite(env) {
    this.asserts = assertClasses.map(Assert => new Assert(env));
  }

  Composite.prototype = {
    reset: callForEach('asserts', 'reset'),
    inject: callForEach('asserts', 'inject'),
    assert: callForEach('asserts', 'assert'),
    restore: callForEach('asserts', 'restore')
  };

  return Composite;
}

import Ember from 'ember';

export default function makeEnv(options) {
  let debugModule = Ember.__loader.require('ember-metal/debug');

  return Ember.merge({
    Ember: Ember,
    runningProdBuild: false,
    getDebugFunction: debugModule.getDebugFunction,
    setDebugFunction: debugModule.setDebugFunction
  }, options);
}

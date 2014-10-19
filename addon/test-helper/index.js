import DeprecationAssert from "./deprecation";
import RemainingViewAssert from "./remaining-view";
import RemainingTemplateAssert from "./remaining-template";
import AssertionAssert from "./assertion";

import {buildCompositeAssert} from "./utils";

var EmberDevTestHelperAssert = buildCompositeAssert([
  DeprecationAssert,
  RemainingViewAssert,
  RemainingTemplateAssert,
  AssertionAssert
]);

export default EmberDevTestHelperAssert;

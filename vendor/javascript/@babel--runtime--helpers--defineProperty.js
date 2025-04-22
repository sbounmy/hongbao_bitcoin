// @babel/runtime/helpers/defineProperty@7.26.10 downloaded from https://unpkg.com/@babel/runtime@7.26.10/helpers/esm/defineProperty.js

import toPropertyKey from "./toPropertyKey.js";
function _defineProperty(e, r, t) {
  return (r = toPropertyKey(r)) in e ? Object.defineProperty(e, r, {
    value: t,
    enumerable: !0,
    configurable: !0,
    writable: !0
  }) : e[r] = t, e;
}
export { _defineProperty as default };
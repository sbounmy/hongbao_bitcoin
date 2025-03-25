// @babel/runtime/helpers/typeof@7.26.10 downloaded from https://unpkg.com/@babel/runtime@7.26.10/helpers/esm/typeof.js

function _typeof(o) {
  "@babel/helpers - typeof";

  return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (o) {
    return typeof o;
  } : function (o) {
    return o && "function" == typeof Symbol && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o;
  }, _typeof(o);
}
export { _typeof as default };
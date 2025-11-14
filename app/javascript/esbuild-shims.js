// app/javascript/esbuild-shims.js
import { Buffer as BufferPolyfill } from 'buffer';
import processPolyfill from 'process/browser'; // 'process/browser' is a common polyfill for 'process'

// Provide global object for Node.js compatibility in browser
if (typeof globalThis.global === 'undefined') {
  globalThis.global = globalThis;
}

// Provide Buffer globally if it's not already defined
if (typeof globalThis.Buffer === 'undefined') {
  globalThis.Buffer = BufferPolyfill;
}

// Provide process globally if it's not already defined
if (typeof globalThis.process === 'undefined') {
  globalThis.process = processPolyfill;
  // You might want to be more specific with what parts of process you polyfill, e.g.,
  // globalThis.process = { ...processPolyfill, env: { NODE_ENV: 'development', ... } };
} else {
  // If process exists, ensure specific properties like `env` also exist if needed
  if (typeof globalThis.process.env === 'undefined') {
    globalThis.process.env = { NODE_ENV: 'development' }; // Example
  }
}
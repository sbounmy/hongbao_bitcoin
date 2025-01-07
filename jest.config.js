module.exports = {
  "testPathIgnorePatterns": [
    "node_modules/",
    "config/webpack/test.js",
    "vendor/bundle/ruby"
  ],
  "moduleDirectories": [
    "node_modules",
    "app/javascript"
  ],
  "collectCoverage": true,
  "coverageReporters": [
    "text",
    "html"
  ],
  "coverageDirectory": "coveragejs",
  "setupFiles": [
    "<rootDir>/test/javascript/setup.js"
  ]
}

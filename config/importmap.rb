# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/services", under: "services"
pin_all_from "app/javascript/services/bitcoin", under: "services/bitcoin"

pin "html2canvas-pro" # @1.5.8
pin "jspdf", to: "https://cdn.jsdelivr.net/npm/jspdf@3.0.1/dist/jspdf.es.min.js"

# Add html5-qrcode with ga.jspm.io
pin "qr-scanner", to: "https://ga.jspm.io/npm:qr-scanner@1.4.2/qr-scanner.min.js"
pin "qr-scanner-worker", to: "https://ga.jspm.io/npm:qr-scanner@1.4.2/qr-scanner-worker.min.js"

# jsPDF and its dependencies
pin "@babel/runtime/helpers/typeof", to: "@babel--runtime--helpers--typeof.js" # @7.26.10
pin "@babel/runtime/helpers/asyncToGenerator", to: "@babel--runtime--helpers--asyncToGenerator.js" # @7.26.10
pin "@babel/runtime/helpers/classCallCheck", to: "https://ga.jspm.io/npm:@babel/runtime@7.26.10/helpers/classCallCheck.js"
pin "@babel/runtime/helpers/createClass", to: "https://ga.jspm.io/npm:@babel/runtime@7.26.10/helpers/createClass.js"
pin "@babel/runtime/regenerator", to: "https://ga.jspm.io/npm:@babel/runtime@7.26.10/regenerator/index.js"
pin "fflate", to: "https://cdn.jsdelivr.net/npm/fflate@0.8.2/+esm"

# Bitcoin-related dependencies
pin "bitcoinjs-lib", to: "https://ga.jspm.io/npm:bitcoinjs-lib@6.1.7/src/index.js"
pin "@noble/hashes/crypto", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/crypto.js"
pin "@noble/hashes/ripemd160", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/ripemd160.js"
pin "@noble/hashes/sha1", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/sha1.js"
pin "@noble/hashes/sha256", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/sha256.js"
pin "base-x" # @5.0.1
pin "bech32", to: "https://ga.jspm.io/npm:bech32@2.0.0/dist/index.js"
pin "bip174", to: "https://ga.jspm.io/npm:bip174@2.1.1/src/lib/psbt.js"
pin "bip174/src/lib/converter/varint", to: "https://ga.jspm.io/npm:bip174@2.1.1/src/lib/converter/varint.js"
pin "bip174/src/lib/utils", to: "https://ga.jspm.io/npm:bip174@2.1.1/src/lib/utils.js"
pin "bs58", to: "https://ga.jspm.io/npm:bs58@5.0.0/index.js"
pin "bs58check", to: "https://ga.jspm.io/npm:bs58check@3.0.1/index.js"
pin "buffer", to: "https://ga.jspm.io/npm:@jspm/core@2.1.0/nodelibs/browser/buffer.js"
pin "safe-buffer", to: "https://ga.jspm.io/npm:safe-buffer@5.2.1/index.js"
pin "typeforce", to: "https://ga.jspm.io/npm:typeforce@1.18.0/index.js"
pin "varuint-bitcoin", to: "https://ga.jspm.io/npm:varuint-bitcoin@1.1.2/index.js"

# Additional dependencies for noble hashes
pin "@noble/hashes/crypto", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/esm/crypto.js", preload: true
pin "@noble/hashes/ripemd160", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/esm/ripemd160.js"
pin "@noble/hashes/sha1", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/esm/sha1.js"
pin "@noble/hashes/sha256", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/esm/sha256.js"
pin "@noble/hashes/utils", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/esm/utils.js"

# ECPair and secp256k1
pin "ecpair", to: "https://ga.jspm.io/npm:ecpair@3.0.0-rc.0/src/esm/index.js"
pin "secp256k1", to: "https://ga.jspm.io/npm:@bitcoinerlab/secp256k1@1.2.0/dist/index.js"
pin "valibot", to: "https://ga.jspm.io/npm:valibot@1.0.0-beta.9/dist/index.js"
pin "wif", to: "https://ga.jspm.io/npm:wif@5.0.0/src/esm/index.js"
pin "uint8array-tools", to: "https://ga.jspm.io/npm:uint8array-tools@0.0.9/src/mjs/browser.js"

pin "@noble/curves/secp256k1", to: "https://ga.jspm.io/npm:@noble/curves@1.7.0/secp256k1.js"
pin "@noble/curves/abstract/modular", to:  "https://ga.jspm.io/npm:@noble/curves@1.7.0/abstract/modular.js"
pin "@noble/curves/abstract/utils", to: "https://ga.jspm.io/npm:@noble/curves@1.7.0/abstract/utils.js"
pin "@noble/hashes/hmac", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.0/esm/hmac.js"

pin "buffer", to: "https://ga.jspm.io/npm:buffer@6.0.3/index.js"
pin "base64-js", to: "https://ga.jspm.io/npm:base64-js@1.5.1/index.js"
pin "ieee754", to: "https://ga.jspm.io/npm:ieee754@1.2.1/index.js"

pin "bip39"
pin "bip32", to: "https://ga.jspm.io/npm:bip32@4.0.0/src/index.js"

# Bip32 dependencies
pin "@scure/base", to: "https://ga.jspm.io/npm:@scure/base@1.2.1/lib/esm/index.js"
pin "@noble/hashes/sha512", to: "https://ga.jspm.io/npm:@noble/hashes@1.6.1/esm/sha512.js"

pin "qrcode", to: "https://ga.jspm.io/npm:qrcode@1.5.3/lib/browser.js"
pin "dijkstrajs", to: "https://ga.jspm.io/npm:dijkstrajs@1.0.3/dijkstra.js"
pin "encode-utf8", to: "https://ga.jspm.io/npm:encode-utf8@1.0.3/index.js"

# Bitcoin message signing
pin "bitcoinjs-message", to: "https://ga.jspm.io/npm:bitcoinjs-message@2.2.0/index.js"
pin "buffer-equals", to: "https://ga.jspm.io/npm:buffer-equals@1.0.4/index.js"
pin "create-hash", to: "https://ga.jspm.io/npm:create-hash@1.2.0/browser.js"
pin "inherits", to: "https://ga.jspm.io/npm:inherits@2.0.4/inherits_browser.js"
pin "md5.js", to: "https://ga.jspm.io/npm:md5.js@1.3.5/index.js"
pin "ripemd160", to: "https://ga.jspm.io/npm:ripemd160@2.0.2/index.js"
pin "sha.js", to: "https://ga.jspm.io/npm:sha.js@2.4.11/index.js"
pin "cipher-base", to: "https://ga.jspm.io/npm:cipher-base@1.0.6/index.js"
pin "hash-base", to: "https://ga.jspm.io/npm:hash-base@3.1.0/index.js"
pin "readable-stream", to: "https://ga.jspm.io/npm:readable-stream@3.6.2/readable-browser.js"
pin "events", to: "https://ga.jspm.io/npm:@jspm/core@2.1.0/nodelibs/browser/events.js"
pin "#lib/internal/streams/stream.js", to: "https://ga.jspm.io/npm:readable-stream@3.6.2/lib/internal/streams/stream-browser.js"
pin "util", to: "https://ga.jspm.io/npm:@jspm/core@2.1.0/nodelibs/browser/util.js"
pin "process", to: "https://ga.jspm.io/npm:@jspm/core@2.1.0/nodelibs/browser/process.js"
pin "string_decoder", to: "https://ga.jspm.io/npm:@jspm/core@2.1.0/nodelibs/browser/string_decoder.js"
pin "#lib/internal/streams/from.js", to: "https://ga.jspm.io/npm:readable-stream@3.6.2/lib/internal/streams/from-browser.js"
pin "util-deprecate", to: "https://ga.jspm.io/npm:util-deprecate@1.0.2/browser.js"
pin "stream", to: "https://ga.jspm.io/npm:@jspm/core@2.1.0/nodelibs/browser/stream.js"

pin "stimulus-use" # @0.52.3
pin "@stimulus-components/scroll-to", to: "@stimulus-components--scroll-to.js" # @5.0.1
pin "@stimulus-components/dropdown", to: "@stimulus-components--dropdown.js" # @3.0.0
pin "@stimulus-components/reveal", to: "@stimulus-components--reveal.js" # @5.0.0
pin "stimulus-textarea-autogrow" # @4.1.0

pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
pin "@babel/runtime/helpers/defineProperty", to: "@babel--runtime--helpers--defineProperty.js" # @7.26.10
pin "canvg" # @3.0.11

# Pin npm packages by running ./bin/importmap
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Bitcoin libraries from unpkg
# pin "bitcoinjs-lib", to: "https://cdn.jsdelivr.net/npm/bitcoinjs-lib@5.1.0/src/index.js"
# pin "bitcoinjs-lib", to: "https://unpkg.com/bitcoinjs-lib@6.1.5"
pin "bip39", to: "bip39.browser.js"
pin "@noble/hashes/sha256", to: "https://ga.jspm.io/npm:@noble/hashes@1.1.2/sha256.js"
pin "@noble/hashes/sha512", to: "https://ga.jspm.io/npm:@noble/hashes@1.1.2/sha512.js"
pin "@noble/hashes/pbkdf2", to: "https://ga.jspm.io/npm:@noble/hashes@1.1.2/pbkdf2.js"
pin "@noble/hashes/utils", to: "https://ga.jspm.io/npm:@noble/hashes@1.1.2/utils.js"

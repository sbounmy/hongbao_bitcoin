import { Controller } from "@hotwired/stimulus"
import * as bip39Module from "bip39"

export default class extends Controller {
  connect() {
    console.log("Bitcoin Test Controller Connected")
    try {
      // Log the entire module to see what's available
      console.log("BIP39 Module:", bip39Module)

      // Try different ways to access generateMnemonic
      if (typeof bip39Module === 'function') {
        // If the module itself is the function
        const mnemonic = bip39Module()
        console.log("Method 1 mnemonic:", mnemonic)
      } else if (bip39Module.default && typeof bip39Module.default.generateMnemonic === 'function') {
        // If it's nested under default
        const mnemonic = bip39Module.default.generateMnemonic()
        console.log("Method 2 mnemonic:", mnemonic)
      } else if (typeof bip39Module.generateMnemonic === 'function') {
        // If it's a direct property
        const mnemonic = bip39Module.generateMnemonic()
        console.log("Method 3 mnemonic:", mnemonic)
      } else {
        console.log("Available methods:", Object.keys(bip39Module))
        throw new Error("Could not find generateMnemonic method")
      }
    } catch (error) {
      console.error("Bitcoin initialization error:", error)
    }
  }
}




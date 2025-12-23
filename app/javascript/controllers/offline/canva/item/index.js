// Item controllers
import TextController from "./text_controller"
import PortraitController from "./portrait_controller"
import MnemonicTextController from "./mnemonic/text_controller"
import PrivateKeyTextController from "./private_key/text_controller"
import PrivateKeyQrcodeController from "./private_key/qrcode_controller"
import PublicAddressTextController from "./public_address/text_controller"
import PublicAddressQrcodeController from "./public_address/qrcode_controller"

// Export base classes for extension
export { default as BaseController } from "./base_controller"
export { default as TextController } from "./text_controller"
export { default as TextKeyController } from "./text_key_controller"
export { default as QrcodeController } from "./qrcode_controller"
export { default as PortraitController } from "./portrait_controller"

// Type → Controller registry
// Type format: "namespace/variant" (e.g., "private_key/qrcode")
const controllers = {
  'text': TextController,
  'portrait': PortraitController,
  'mnemonic/text': MnemonicTextController,
  'private_key/text': PrivateKeyTextController,
  'private_key/qrcode': PrivateKeyQrcodeController,
  'public_address/text': PublicAddressTextController,
  'public_address/qrcode': PublicAddressQrcodeController,
}

// Factory function to create the right controller based on type
export function createItem(name, data, canvaController) {
  const type = data.type || 'text'
  const Controller = controllers[type] || controllers['text']
  return new Controller(name, data, canvaController)
}

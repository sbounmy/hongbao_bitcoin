import { application } from "./controllers/application"

// --- Load all controllers from the offline folder ---
import BindingController from "./controllers/offline/binding_controller"
application.register("binding", BindingController)

import BitcoinAddressController from "./controllers/offline/bitcoin_address_controller"
application.register("bitcoin-address", BitcoinAddressController)

import BitcoinController from "./controllers/offline/bitcoin_controller"
application.register("bitcoin", BitcoinController)

import BitcoinKeyController from "./controllers/offline/bitcoin_key_controller"
application.register("bitcoin-key", BitcoinKeyController)

import BitcoinLegacyKeyController from "./controllers/offline/bitcoin_legacy_key_controller"
application.register("bitcoin-legacy-key", BitcoinLegacyKeyController)

import BitcoinMnemonicController from "./controllers/offline/bitcoin_mnemonic_controller"
application.register("bitcoin-mnemonic", BitcoinMnemonicController)

import BitcoinSegwitKeyController from "./controllers/offline/bitcoin_segwit_key_controller"
application.register("bitcoin-segwit-key", BitcoinSegwitKeyController)

import BitcoinWifController from "./controllers/offline/bitcoin_wif_controller"
application.register("bitcoin-wif", BitcoinWifController)

import CanvaController from "./controllers/offline/canva_controller"
application.register("canva", CanvaController)

import CanvaItemController from "./controllers/offline/canva_item_controller"
application.register("canva-item", CanvaItemController)

import DialogKeyController from "./controllers/offline/dialog_key_controller"
application.register("dialog-key", DialogKeyController)

import PdfController from "./controllers/offline/pdf_controller"
application.register("pdf", PdfController)

import PrivateKeyController from "./controllers/offline/private_key_controller"
application.register("private-key", PrivateKeyController)

import QrCodeController from "./controllers/offline/qr_code_controller"
application.register("qr-code", QrCodeController)

import StepsController from "./controllers/offline/steps_controller"
application.register("steps", StepsController)
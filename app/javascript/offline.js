import { application } from "./controllers/application"

// --- Load all controllers from the offline folder ---


import FormController from "./controllers/offline/form_controller"
application.register("form", FormController)

import FormWalletController from "./controllers/offline/form_wallet_controller"
application.register("form-wallet", FormWalletController)

import BindingController from "./controllers/offline/binding_controller"
application.register("binding", BindingController)

import WordController from "./controllers/offline/word_controller"
application.register("word", WordController)

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

import CanvaItemController from "./controllers/offline/canva_item_controller"
application.register("canva-item", CanvaItemController)

import TextItemController from "./controllers/offline/text_item_controller"
application.register("text-item", TextItemController)

import ImageItemController from "./controllers/offline/image_item_controller"
application.register("image-item", ImageItemController)

import PortraitItemController from "./controllers/offline/portrait_item_controller"
application.register("portrait-item", PortraitItemController)

import PdfController from "./controllers/offline/pdf_controller"
application.register("pdf", PdfController)

import PrivateKeyController from "./controllers/offline/private_key_controller"
application.register("private-key", PrivateKeyController)

import QrCodeController from "./controllers/offline/qr_code_controller"
application.register("qr-code", QrCodeController)

import KeysInputController from "./controllers/offline/keys_input_controller"
application.register("keys-input", KeysInputController)

import ThemeSelectController from "./controllers/offline/theme_select_controller"
application.register("theme-select", ThemeSelectController)

import PasswordVisibility from "@stimulus-components/password-visibility"
application.register("password-visibility", PasswordVisibility)

import TextEditController from "./controllers/text_edit_controller"
application.register("text-edit", TextEditController)

// --- New Editor Architecture ---
import PaperEditorController from "./controllers/paper_editor_controller"
application.register("paper-editor", PaperEditorController)
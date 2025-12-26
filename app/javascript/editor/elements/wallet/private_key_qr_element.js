import { WalletQRElement } from "./qr_element"

// Private key QR element - displays QR code of private key
export class PrivateKeyQRElement extends WalletQRElement {
  static drawer = 'keys-drawer'
  static dataKey = 'private_key_qrcode'
}

import { WalletQRElement } from "./qr_element"

// Public address QR element - displays QR code of public address
export class PublicAddressQRElement extends WalletQRElement {
  static drawer = 'style-drawer'
  static dataKey = 'public_address_qrcode'
}

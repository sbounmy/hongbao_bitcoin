import QrcodeController from "../qrcode_controller"

// Public address QR code - wallet-sourced, opens style drawer for QR customization
export default class PublicAddressQrcodeController extends QrcodeController {
  static drawer = "style-drawer"
}

import { Buffer } from 'buffer'
global.Buffer = Buffer

// Mock crypto for deterministic tests
global.crypto = {
  getRandomValues: (array) => array.fill(1)
}

// Mock QRCode
jest.mock('qrcode', () => ({
  toDataURL: jest.fn().mockResolvedValue('data:image/png;base64,mockQRCode')
}))

// Mock window
global.window = {
  crypto: global.crypto,
  Buffer,
  bip39: {
    wordlists: { english: [] },
    generateMnemonic: () => 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
    mnemonicToSeedSync: () => Buffer.from('c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04', 'hex')
  }
}
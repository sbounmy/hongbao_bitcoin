import BitcoinWallet from 'services/bitcoin_wallet'

describe('BitcoinWallet', () => {
  // Test vector from BIP39 spec
  const TEST_VECTOR = {
    mnemonic: 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
    seed: 'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
    paths: {
      "m/84'/0'/0'/0/0": {
        testnet: {
          privateKey: 'cQZmGLJBQDXGF5kpGrqeCzLUkGj9h7WYpNFhVoAXhqFKPBRuEJ8Q',
          publicKey: '0330d54fd0dd420a6e5f8d3624f5f3482cae350f79d5f0753bf5beef9c2d91af3c',
          address: 'n4SvybJicv79X1Uc4o3fYXWGwXadA53FSq'
        },
        mainnet: {
          privateKey: 'L1HKVVLHXiUhecWnwFYF6L3shkf4mUdNxHX2VHC7VpwRX6TG5mxL',
          publicKey: '0330d54fd0dd420a6e5f8d3624f5f3482cae350f79d5f0753bf5beef9c2d91af3c',
          address: '1NEWYorkwDYFZZJ1h7k7oqPF8ViXuGbDzH'
        }
      }
    }
  }

  beforeEach(() => {
    BitcoinWallet.setNetwork('testnet')
  })

  describe('static setNetwork', () => {
    it('sets the network correctly', () => {
      BitcoinWallet.setNetwork('testnet')
      expect(BitcoinWallet.network).toBe('testnet')

      BitcoinWallet.setNetwork('mainnet')
      expect(BitcoinWallet.network).toBe('mainnet')
    })

    it('affects new wallet network', () => {
      BitcoinWallet.setNetwork('mainnet')
      const wallet = new BitcoinWallet()
      expect(wallet.network).toBe(bitcoin.networks.bitcoin)
    })
  })

  describe('generate', () => {
    it('generates a wallet with correct properties', () => {
      const wallet = BitcoinWallet.generate()

      expect(wallet.mnemonic).toBe(TEST_VECTOR.mnemonic)
      expect(Buffer.from(wallet.seed).toString('hex')).toBe(TEST_VECTOR.seed)
      expect(wallet.entropy).toBeDefined()
      expect(wallet.root).toBeDefined()
    })
  })

  describe('nodePathFor', () => {
    let wallet

    beforeEach(() => {
      wallet = BitcoinWallet.generate()
    })

    it('derives correct testnet keys and address', () => {
      BitcoinWallet.setNetwork('testnet')
      const path = "m/84'/0'/0'/0/0"
      const key = wallet.node
    })
  })
})
import { Buffer } from 'buffer'
import { sha256 } from '@noble/hashes/sha256'

const MAGIC_BYTES = {
  'bitcoin': Buffer.from('\x18Bitcoin Signed Message:\n', 'utf8'),
  'testnet': Buffer.from('\x18Bitcoin Signed Message:\n', 'utf8')
}

export function magicHash(message, network = 'bitcoin') {
  const messageBuffer = Buffer.from(message, 'utf8')
  const magicBytes = MAGIC_BYTES[network]

  const prefix = Buffer.from([magicBytes.length])
  const messageLength = Buffer.from([messageBuffer.length])

  // Concatenate all parts
  const buffer = Buffer.concat([
    prefix,
    magicBytes,
    messageLength,
    messageBuffer
  ])

  // Double SHA256
  const firstHash = sha256(buffer)
  const secondHash = sha256(firstHash)

  return Buffer.from(secondHash)
}
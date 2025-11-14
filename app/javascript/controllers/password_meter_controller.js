import { Controller } from "@hotwired/stimulus"

// Password Strength Meter Controller
// A reusable Stimulus controller for real-time password strength evaluation
// Can be extracted as @stimulus-components/password-meter

export default class extends Controller {
  static targets = [
    "input",
    "meter",
    "meterFill",
    "meterText",
    "requirement",
    "lengthRequirement",
    "uppercaseRequirement",
    "lowercaseRequirement",
    "numberRequirement",
    "specialRequirement"
  ]

  static values = {
    minLength: { type: Number, default: 8 },
    maxLength: { type: Number, default: 128 },
    requireUppercase: { type: Boolean, default: true },
    requireLowercase: { type: Boolean, default: true },
    requireNumbers: { type: Boolean, default: true },
    requireSpecial: { type: Boolean, default: true },
    specialChars: { type: String, default: "!@#$%^&*()_+-=[]{}|;:,.<>?" }
  }

  static classes = [
    "weak",
    "fair",
    "strong",
    "veryStrong",
    "requirementMet",
    "requirementUnmet"
  ]

  connect() {
    this.evaluate()
  }

  evaluate() {
    const password = this.hasInputTarget ? this.inputTarget.value : ""
    const analysis = this.analyzePassword(password)

    this.updateMeter(analysis.score, analysis.strength)
    this.updateRequirements(analysis.requirements)
    this.dispatchEvents(analysis)
  }

  analyzePassword(password) {
    const requirements = {
      length: password.length >= this.minLengthValue,
      uppercase: !this.requireUppercaseValue || /[A-Z]/.test(password),
      lowercase: !this.requireLowercaseValue || /[a-z]/.test(password),
      number: !this.requireNumbersValue || /\d/.test(password),
      special: !this.requireSpecialValue || this.hasSpecialChar(password)
    }

    // Calculate base score
    let score = 0
    let possiblePoints = 0

    // Length scoring (0-25 points)
    if (password.length >= this.minLengthValue) {
      score += 15
      if (password.length >= 12) score += 5
      if (password.length >= 16) score += 5
    }
    possiblePoints += 25

    // Character diversity scoring (0-40 points)
    if (this.requireUppercaseValue) {
      possiblePoints += 10
      if (requirements.uppercase) score += 10
    }
    if (this.requireLowercaseValue) {
      possiblePoints += 10
      if (requirements.lowercase) score += 10
    }
    if (this.requireNumbersValue) {
      possiblePoints += 10
      if (requirements.number) score += 10
    }
    if (this.requireSpecialValue) {
      possiblePoints += 10
      if (requirements.special) score += 10
    }

    // Complexity bonus (0-35 points) - scaled by password length
    // This prevents very short passwords from getting disproportionately high scores
    const uniqueChars = new Set(password).size
    const complexityRatio = password.length > 0 ? uniqueChars / password.length : 0

    // Scale complexity bonus by length: 0% for <4 chars, 50% for 4-7 chars, 100% for >=8 chars
    let lengthMultiplier = 0
    if (password.length >= this.minLengthValue) {
      lengthMultiplier = 1.0
    } else if (password.length >= 4) {
      lengthMultiplier = 0.5
    }

    const complexityBonus = Math.floor(complexityRatio * 35 * lengthMultiplier)
    score += complexityBonus
    possiblePoints += 35

    // Deductions for common patterns (but don't prevent 100% score)
    const baseScore = score
    if (this.hasRepeatedChars(password)) score = Math.max(baseScore * 0.9, score - 10)
    if (this.hasSequentialChars(password)) score = Math.max(baseScore * 0.9, score - 10)
    if (this.hasKeyboardPattern(password)) score = Math.max(baseScore * 0.9, score - 10)

    // Check if all requirements are met (moved up to use in score calculation)
    const allRequirementsMet = Object.values(requirements).every(met => met)

    // Normalize score to 0-100
    const normalizedScore = Math.max(0, Math.min(100, (score / possiblePoints) * 100))

    // Apply score caps based on requirements
    let finalScore
    if (!allRequirementsMet) {
      // If any requirement is missing, cap at Fair level (< 50%)
      finalScore = Math.min(49, normalizedScore)
    } else if (password.length >= 16) {
      // If all requirements met and long password, ensure at least 75% (Very Strong)
      finalScore = Math.max(75, normalizedScore)
    } else {
      finalScore = normalizedScore
    }

    // Determine strength level
    let strength
    if (finalScore < 25) strength = "weak"
    else if (finalScore < 50) strength = "fair"
    else if (finalScore < 75) strength = "strong"
    else strength = "veryStrong"

    return {
      score: finalScore,
      strength,
      requirements,
      allRequirementsMet,
      password
    }
  }

  hasSpecialChar(password) {
    const regex = new RegExp(`[${this.specialCharsValue.replace(/[\[\]\\-]/g, '\\$&')}]`)
    return regex.test(password)
  }

  hasRepeatedChars(password) {
    return /(.)\1{2,}/.test(password)
  }

  hasSequentialChars(password) {
    const sequences = [
      "abcdefghijklmnopqrstuvwxyz",
      "0123456789",
      "qwertyuiop",
      "asdfghjkl",
      "zxcvbnm"
    ]

    const lowerPassword = password.toLowerCase()
    return sequences.some(seq => {
      for (let i = 0; i < lowerPassword.length - 2; i++) {
        const substr = lowerPassword.substring(i, i + 3)
        if (seq.includes(substr) || seq.includes(substr.split('').reverse().join(''))) {
          return true
        }
      }
      return false
    })
  }

  hasKeyboardPattern(password) {
    const patterns = [
      "qwerty", "asdfgh", "zxcvbn",
      "123456", "098765",
      "qazwsx", "qweasd"
    ]

    const lowerPassword = password.toLowerCase()
    return patterns.some(pattern => lowerPassword.includes(pattern))
  }

  updateMeter(score, strength) {
    if (!this.hasMeterFillTarget || !this.hasMeterTextTarget) return

    // Update fill width
    this.meterFillTarget.style.width = `${score}%`

    // Remove all background classes then add the correct one
    this.meterFillTarget.classList.remove('bg-red-500', 'bg-orange-500', 'bg-yellow-500', 'bg-green-500')

    // Apply strength class
    const bgClasses = {
      weak: "bg-red-500",
      fair: "bg-orange-500",
      strong: "bg-yellow-500",
      veryStrong: "bg-green-500"
    }
    this.meterFillTarget.classList.add(bgClasses[strength])

    // Update text
    const strengthText = {
      weak: "Weak",
      fair: "Fair",
      strong: "Strong",
      veryStrong: "Very Strong"
    }
    this.meterTextTarget.textContent = strengthText[strength]

    // Update badge color classes
    this.meterTextTarget.classList.remove(
      'text-white/50',
      'badge-error',
      'badge-warning',
      'badge-info',
      'badge-success'
    )
    const badgeClasses = {
      weak: "badge-error",
      fair: "badge-warning",
      strong: "badge-info",
      veryStrong: "badge-success"
    }
    this.meterTextTarget.classList.add(badgeClasses[strength])
  }

  updateRequirements(requirements) {
    // Update length requirement
    if (this.hasLengthRequirementTarget) {
      this.updateRequirement(this.lengthRequirementTarget, requirements.length)
    }

    // Update uppercase requirement
    if (this.hasUppercaseRequirementTarget) {
      this.updateRequirement(this.uppercaseRequirementTarget, requirements.uppercase)
    }

    // Update lowercase requirement
    if (this.hasLowercaseRequirementTarget) {
      this.updateRequirement(this.lowercaseRequirementTarget, requirements.lowercase)
    }

    // Update number requirement
    if (this.hasNumberRequirementTarget) {
      this.updateRequirement(this.numberRequirementTarget, requirements.number)
    }

    // Update special requirement
    if (this.hasSpecialRequirementTarget) {
      this.updateRequirement(this.specialRequirementTarget, requirements.special)
    }
  }

  updateRequirement(element, isMet) {
    // Update color classes
    element.classList.remove('text-green-400', 'text-white/60')
    if (isMet) {
      element.classList.add('text-green-400')
    } else {
      element.classList.add('text-white/60')
    }

    // Update icon if present
    const icon = element.querySelector('[data-password-meter-icon]')
    if (icon) {
      icon.textContent = isMet ? '✓' : '✗'
    }

    // Update aria attributes for accessibility
    element.setAttribute('aria-invalid', !isMet)
  }

  dispatchEvents(analysis) {
    // Dispatch change event with analysis details
    this.dispatch('change', {
      detail: {
        score: analysis.score,
        strength: analysis.strength,
        requirements: analysis.requirements,
        allRequirementsMet: analysis.allRequirementsMet,
        password: analysis.password
      }
    })

    // Dispatch specific strength level events
    this.dispatch(analysis.strength, {
      detail: {
        score: analysis.score,
        allRequirementsMet: analysis.allRequirementsMet
      }
    })

    // Dispatch requirements met event
    if (analysis.allRequirementsMet) {
      this.dispatch('requirements-met', {
        detail: {
          score: analysis.score,
          strength: analysis.strength
        }
      })
    }

    // Dispatch valid event for form validation
    // Password meter is advisory only - all passwords are valid (weak or strong)
    // This allows users to download PDF with any password strength
    this.dispatch('valid', { detail: analysis })
  }
}
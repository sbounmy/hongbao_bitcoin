module.exports = {
  safelist: [
    'aspect-[150/75]',  // Landscape aspect ratio
    'aspect-[63/88]',   // Portrait aspect ratio (standard trading card)
    // Frame dimension classes for PDF preview
    'w-[150mm]', 'h-[75mm]',   // Landscape
    'w-[63mm]', 'h-[88mm]',    // Portrait
    'min-h-[88mm]',            // Portrait layout
    'w-[150mm]',               // Landscape layout
  ],
  // ... rest of your config
}
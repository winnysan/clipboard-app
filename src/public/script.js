/**
 * Initialize
 */

console.log(
  '%cScript loaded successfully',
  'color: white; background-color: green; font-weight: bold; padding: 2px 4px; border-radius: 3px;'
)

/**
 * Scroll snapping
 */

let isScrolling
const SNAP_THRESHOLD = 200

window.addEventListener('scroll', () => {
  clearTimeout(isScrolling)

  isScrolling = setTimeout(() => {
    const sections = document.querySelectorAll('section')
    let closestSection = null
    let minDistance = Infinity

    sections.forEach(section => {
      const rect = section.getBoundingClientRect()
      const distance = Math.abs(rect.top)

      if (distance < minDistance) {
        minDistance = distance
        closestSection = section
      }
    })

    if (closestSection && Math.abs(closestSection.getBoundingClientRect().top) <= SNAP_THRESHOLD) {
      closestSection.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }, 200)
})

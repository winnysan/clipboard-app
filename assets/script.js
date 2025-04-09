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

/**
 * Show image in overlay
 */

document.addEventListener('click', e => {
  const target = e.target

  if (target instanceof HTMLImageElement && target.hasAttribute('data-image')) {
    const overlay = document.createElement('div')
    overlay.classList.add('overlay')

    const wrapper = document.createElement('div')
    wrapper.classList.add('wrapper')

    const img = document.createElement('img')
    img.src = target.src
    img.classList.add('img')

    const caption = document.createElement('span')
    caption.textContent = target.alt || ''
    caption.classList.add('caption')

    const closeButton = document.createElement('button')
    closeButton.innerHTML = '&times;'
    closeButton.classList.add('close')

    wrapper.appendChild(img)
    wrapper.appendChild(caption)
    overlay.appendChild(wrapper)
    overlay.appendChild(closeButton)
    document.body.appendChild(overlay)

    closeButton.addEventListener('click', () => {
      overlay.remove()
    })

    const escHandler = e => {
      if (e.key === 'Escape') {
        overlay.remove()
        document.removeEventListener('keydown', escHandler)
      }
    }

    document.addEventListener('keydown', escHandler)
  }
})

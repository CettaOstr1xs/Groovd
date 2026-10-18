/**
 * GROOVD // Official Android Download Portal Interactions
 * Neo-Brutalist Experience Suite
 */

document.addEventListener('DOMContentLoaded', () => {
  initSplashScreen();
  initDownload();
  initRatingPlayground();
  initSideloadAccordion();
  initStickyBar();
  initDeviceBadge();
});

/* =========================================================================
   0. In-App Authentic Splash Screen (Same as Flutter App)
   ========================================================================= */
function initSplashScreen() {
  const splash = document.getElementById('splash-screen');
  if (!splash) return;

  let dismissed = false;
  function dismissSplash() {
    if (dismissed) return;
    dismissed = true;
    splash.classList.add('splash-fade-out');
    setTimeout(() => {
      splash.remove();
    }, 450);
  }

  // Tap or click to skip instantly (same as in-app onTap: _proceed)
  splash.addEventListener('click', dismissSplash);

  // Auto transition after 1900ms (exact match with in-app 1900ms splash duration)
  setTimeout(dismissSplash, 1900);
}

/* =========================================================================
   1. Dynamic Download URL Management
   ========================================================================= */
function initDownload() {
  const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
  const baseUrl = isLocal ? window.location.origin : 'https://groovd-43b81.web.app';
  const downloadUrl = `${baseUrl}/download/groovd-latest.apk`;

  // Update download link hrefs
  const downloadBtns = document.querySelectorAll('.js-download-link');
  downloadBtns.forEach(btn => {
    btn.href = downloadUrl;
  });
}

/* =========================================================================
   2. Device Detection (Android-Specific Prompts)
   ========================================================================= */
function initDeviceBadge() {
  const isAndroid = /android/i.test(navigator.userAgent);
  const deviceNotice = document.getElementById('device-notice');

  if (isAndroid) {
    if (deviceNotice) {
      deviceNotice.innerHTML = `
        <span class="badge-android">
          <span class="dot-live"></span>
          ANDROID DETECTED — READY FOR DIRECT INSTALL
        </span>
      `;
    }
  } else {
    if (deviceNotice) {
      deviceNotice.innerHTML = `
        <span class="badge-desktop">
          DIRECT APK DOWNLOAD AVAILABLE // READY FOR INSTALL
        </span>
      `;
    }
  }
}

/* =========================================================================
   3. Interactive 10.0 Decimal Rating Playground
   ========================================================================= */
function initRatingPlayground() {
  const slider = document.getElementById('demo-rating-slider');
  const scoreVal = document.getElementById('demo-score-value');
  const descriptor = document.getElementById('demo-descriptor');
  const spikeSignContainer = document.getElementById('demo-spike-sign');
  const liveCard = document.getElementById('demo-rating-card');

  if (!slider || !scoreVal || !descriptor || !spikeSignContainer) return;

  function updateRating(val) {
    const score = parseFloat(val);
    scoreVal.textContent = score.toFixed(1);

    let tagText = 'MEDIOCRE';
    let tagColor = 'var(--text-muted)';
    let signSvg = '';
    let accentBorder = 'var(--border-dark)';

    if (score <= 2.0) {
      tagText = 'CRITICAL SKIP';
      tagColor = 'var(--vermillion)';
      accentBorder = 'var(--vermillion)';
      signSvg = createHollowSpikeSvg('var(--vermillion)');
    } else if (score <= 4.0) {
      tagText = 'DISAPPOINTING';
      tagColor = 'var(--vermillion)';
      accentBorder = 'var(--vermillion)';
      signSvg = createHollowSpikeSvg('var(--vermillion)');
    } else if (score <= 6.0) {
      tagText = 'MEDIOCRE';
      tagColor = 'var(--text-muted)';
      accentBorder = 'var(--border-dark)';
      signSvg = createHollowSpikeSvg('var(--text-muted)');
    } else if (score <= 7.5) {
      tagText = 'DECENT LISTEN';
      tagColor = 'var(--cyber-cyan)';
      accentBorder = 'var(--cyber-cyan)';
      signSvg = createFullSpikeSvg('var(--cyber-cyan)');
    } else if (score <= 8.9) {
      tagText = 'HIGHLY PRAISED';
      tagColor = 'var(--cyber-cyan)';
      accentBorder = 'var(--cyber-cyan)';
      signSvg = createFullSpikeSvg('var(--cyber-cyan)');
    } else if (score <= 9.4) {
      tagText = "CRITIC'S ESSENTIAL";
      tagColor = 'var(--acid-lime)';
      accentBorder = 'var(--acid-lime)';
      signSvg = createFullSpikeSvg('var(--acid-lime)');
    } else {
      tagText = 'MASTERPIECE';
      tagColor = 'var(--acid-lime)';
      accentBorder = 'var(--acid-lime)';
      signSvg = createEightPointSpikeSvg('var(--acid-lime)');
    }

    descriptor.textContent = tagText;
    descriptor.style.color = tagColor;
    descriptor.style.borderColor = tagColor;
    scoreVal.style.color = tagColor;
    spikeSignContainer.innerHTML = signSvg;

    if (liveCard) {
      liveCard.style.setProperty('--card-glow', tagColor);
    }

    // Interactive slider background fill percentage
    const percent = ((score / 10.0) * 100).toFixed(1);
    slider.style.background = `linear-gradient(to right, ${tagColor} 0%, ${tagColor} ${percent}%, #222222 ${percent}%, #222222 100%)`;
  }

  slider.addEventListener('input', (e) => {
    updateRating(e.target.value);
  });

  // Initial trigger
  updateRating(slider.value || 9.6);
}

/* =========================================================================
   Official In-App Rating Spike Sign (Exact match with RatingSpikeSign.dart)
   ========================================================================= */

// Rating <= 6.0: Hollow stroked 4-point classic spike
function createHollowSpikeSvg(color) {
  return `
    <svg width="18" height="24" viewBox="0 0 24 32" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M 12 1 Q 13.54 13.9 23 16 Q 13.54 18.1 12 31 Q 10.46 18.1 1 16 Q 10.46 13.9 12 1 Z" />
    </svg>
  `;
}

// 6.1 <= Rating <= 9.4: Solid filled 4-point classic spike
function createFullSpikeSvg(color) {
  return `
    <svg width="18" height="24" viewBox="0 0 24 32" fill="${color}" aria-hidden="true">
      <path d="M 12 1 Q 13.54 13.9 23 16 Q 13.54 18.1 12 31 Q 10.46 18.1 1 16 Q 10.46 13.9 12 1 Z" />
    </svg>
  `;
}

// 9.5 <= Rating <= 10.0: Solid filled 8-point spike (primary + 4 diagonal tapered spikes)
function createEightPointSpikeSvg(color) {
  return `
    <svg width="18" height="24" viewBox="0 0 24 32" fill="${color}" aria-hidden="true">
      <path d="M 12 1 Q 13.54 13.9 23 16 Q 13.54 18.1 12 31 Q 10.46 18.1 1 16 Q 10.46 13.9 12 1 Z" />
      <path d="M 18.07 9.93 Q 13.37 16 18.07 22.07 Q 12 17.37 5.93 22.07 Q 10.63 16 5.93 9.93 Q 12 14.63 18.07 9.93 Z" />
    </svg>
  `;
}

/* =========================================================================
   4. Interactive Android Sideloading Accordion
   ========================================================================= */
function initSideloadAccordion() {
  const steps = document.querySelectorAll('.sideload-step');

  steps.forEach(step => {
    const header = step.querySelector('.step-header');
    if (!header) return;

    header.addEventListener('click', () => {
      const isOpen = step.classList.contains('active');

      // Close all steps
      steps.forEach(s => s.classList.remove('active'));

      // If clicked wasn't open, open it
      if (!isOpen) {
        step.classList.add('active');
      }
    });
  });
}

/* =========================================================================
   5. Sticky Mobile Download Bar
   ========================================================================= */
function initStickyBar() {
  const stickyBar = document.getElementById('sticky-download-bar');
  const heroSection = document.getElementById('hero');

  if (!stickyBar || !heroSection) return;

  const handleSticky = () => {
    if (window.innerWidth > 768) {
      stickyBar.classList.remove('visible');
      return;
    }
    const heroBottom = heroSection.getBoundingClientRect().bottom;
    if (heroBottom < 100) {
      stickyBar.classList.add('visible');
    } else {
      stickyBar.classList.remove('visible');
    }
  };

  window.addEventListener('scroll', handleSticky, { passive: true });
  window.addEventListener('resize', handleSticky, { passive: true });
}

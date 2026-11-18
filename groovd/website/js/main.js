/**
 * GROOVD // Official Android Download Portal Interactions
 * Neo-Brutalist Experience Suite
 */

document.addEventListener('DOMContentLoaded', () => {
  initSplashScreen();
  initDownload();
  initRatingPlayground();
  initCriticConsole();
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
  const baseUrl = isLocal ? window.location.origin : 'https://groovd.web.app';
  const downloadUrl = `${baseUrl}/download/groovd-release.bin`;

  // On homepage, ensure all download CTA buttons route to the download portal page
  const downloadCtaBtns = document.querySelectorAll('.btn-primary-download, .btn-nav-download, .btn-sticky-download');
  downloadCtaBtns.forEach(btn => {
    btn.href = 'download.html';
  });

  // Direct APK download links (e.g. manual fallback buttons)
  const directApkLinks = document.querySelectorAll('.js-direct-apk-link');
  directApkLinks.forEach(btn => {
    btn.href = downloadUrl;
  });
}

/* =========================================================================
   2. Device Detection
   ========================================================================= */
function initDeviceBadge() {
  // Device notice text removed per minimalist redesign
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

/* =========================================================================
   6. GROOVD AI // Resident Critic Console (Zero Emojis • Scramble Decoder)
   ========================================================================= */
function initCriticConsole() {
  const outputEl = document.getElementById('critic-text-output');
  const chipBtns = document.querySelectorAll('.critic-chip-btn');
  const albumEmbed = document.getElementById('critic-album-embed');
  const visionBox = document.getElementById('critic-vision-box');
  const userPromptLabel = document.getElementById('critic-user-prompt-label');

  if (!outputEl || chipBtns.length === 0) return;

  const scenarios = {
    roast: {
      prompt: 'QUERY: WHY DOES DECIMAL SCORING MATTER?',
      showVision: false,
      text: 'The 5-star rating system is broken. Everything collapses into a bland 3 or 4 stars, lost in the grey mush of algorithmic consensus.\n\nA 10.0 decimal system demands real conviction. An 8.2 is a thrilling, deeply flawed underground record with flashes of brilliance. An 8.8 is a future classic. A 9.7 permanently rewires your neurological chemistry.\n\nWhen you score with decimal precision, you stop being a passive listener and start documenting a definitive personal canon.',
      album: {
        title: 'OK COMPUTER',
        artist: 'RADIOHEAD',
        art: 'assets/covers/ok_computer.jpg',
        badge: '9.8 CANON'
      }
    },
    recommend: {
      prompt: 'QUERY: HOW ARE YOU DIFFERENT FROM STREAMING APPS?',
      showVision: false,
      text: 'Streaming algorithms optimize for low-friction background wallpaper—pleasant, predictable tracks designed not to offend so you leave the playlist running.\n\nGROOVD AI is grounded in decades of independent music criticism, underground pressing history, and uncompromising acoustic analysis. It does not recommend what is safe. It recommends what will shake you out of musical complacency.',
      album: {
        title: 'UNKNOWN PLEASURES',
        artist: 'JOY DIVISION',
        art: 'assets/covers/unknown_pleasures.jpg',
        badge: 'CULTURE SHIFT'
      }
    },
    gear: {
      prompt: 'MULTIMODAL: CAN YOU REALLY INSPECT MY RECORD SETUP?',
      showVision: true,
      text: 'Snap a photo of your turntable, your cartridge alignment, or the matrix etchings in your vinyl runout groove.\n\nGROOVD AI detects plinth vibration, tracking angle errors, and room acoustic placement from a single camera shot. It is the difference between hearing compressed surface noise and unlocking the full dynamic headroom of your physical pressings.',
      album: {
        title: 'THE DARK SIDE OF THE MOON',
        artist: 'PINK FLOYD',
        art: 'assets/covers/the_dark_side_of_the_moon.jpg',
        badge: '180G AUDIOPHILE'
      }
    },
    take: {
      prompt: 'QUERY: HOW DOES THIS IMPROVE MY ALBUM REVIEWS?',
      showVision: false,
      text: 'Most album logs are just a forgotten star rating and a date. GROOVD turns your listening history into an active intellectual archive.\n\nDebate your hottest takes, track rating spikes across full tracklists, filter out interludes, and archive your entire physical and digital collection in a private, telemetry-free notebook.',
      album: {
        title: 'TO PIMP A BUTTERFLY',
        artist: 'KENDRICK LAMAR',
        art: 'assets/covers/to_pimp_a_butterfly.jpg',
        badge: 'CRITIC DOSSIER'
      }
    }
  };

  let isScrambling = false;
  const chars = '#$%&*+/<=>?@[\\]^_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  function scrambleDecode(targetText, onDone) {
    if (isScrambling) return;
    isScrambling = true;

    outputEl.textContent = '';
    let currentIdx = 0;
    const totalChars = targetText.length;
    const stepDuration = 18;

    const timer = setInterval(() => {
      let displayStr = targetText.slice(0, currentIdx);

      for (let i = 0; i < 3 && currentIdx + i < totalChars; i++) {
        if (targetText[currentIdx + i] === ' ' || targetText[currentIdx + i] === '\n') {
          displayStr += targetText[currentIdx + i];
        } else {
          displayStr += chars[Math.floor(Math.random() * chars.length)];
        }
      }

      outputEl.textContent = displayStr;
      currentIdx += 2;

      if (currentIdx >= totalChars) {
        clearInterval(timer);
        outputEl.textContent = targetText;
        isScrambling = false;
        if (onDone) onDone();
      }
    }, stepDuration);
  }

  function activateScenario(key) {
    const data = scenarios[key];
    if (!data || isScrambling) return;

    chipBtns.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.scenario === key);
    });

    if (userPromptLabel) {
      userPromptLabel.textContent = data.prompt;
    }

    if (visionBox) {
      visionBox.style.display = data.showVision ? 'flex' : 'none';
    }

    if (albumEmbed) {
      albumEmbed.style.opacity = '0';
      albumEmbed.style.pointerEvents = 'none';
    }

    scrambleDecode(data.text, () => {
      if (albumEmbed && data.album) {
        const titleEl = albumEmbed.querySelector('.critic-album-title');
        const artistEl = albumEmbed.querySelector('.critic-album-artist');
        const badgeEl = albumEmbed.querySelector('.critic-album-badge');
        const artEl = albumEmbed.querySelector('.critic-album-art');

        if (titleEl) titleEl.textContent = data.album.title;
        if (artistEl) artistEl.textContent = data.album.artist;
        if (badgeEl) badgeEl.textContent = data.album.badge;
        if (artEl) artEl.src = data.album.art;

        albumEmbed.style.opacity = '1';
        albumEmbed.style.pointerEvents = 'auto';
      }
    });
  }

  chipBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const scenarioKey = btn.dataset.scenario;
      if (scenarioKey) activateScenario(scenarioKey);
    });
  });

  // Initial trigger
  activateScenario('roast');
}

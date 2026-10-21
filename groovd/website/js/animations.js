/**
 * GROOVD // Advanced Kinetic Motion Engine
 * Powered by GSAP, ScrollTrigger, CustomEase, CustomWiggle, CustomBounce, InertiaPlugin, Observer, SplitText & ScrambleTextPlugin
 * High-Contrast Neo-Brutalist Experience Architecture (Strictly Zero Emojis)
 */

(function() {
  'use strict';

  // Check if GSAP is available
  if (typeof gsap === 'undefined') {
    console.warn('GROOVD: GSAP core not detected');
    return;
  }

  // Register GSAP Plugins safely
  const registeredPlugins = [];
  if (typeof ScrollTrigger !== 'undefined') {
    gsap.registerPlugin(ScrollTrigger);
    registeredPlugins.push('ScrollTrigger');
  }
  if (typeof CustomEase !== 'undefined') {
    gsap.registerPlugin(CustomEase);
    registeredPlugins.push('CustomEase');
  }
  if (typeof CustomBounce !== 'undefined') {
    gsap.registerPlugin(CustomBounce);
    registeredPlugins.push('CustomBounce');
  }
  if (typeof CustomWiggle !== 'undefined') {
    gsap.registerPlugin(CustomWiggle);
    registeredPlugins.push('CustomWiggle');
  }
  if (typeof InertiaPlugin !== 'undefined') {
    gsap.registerPlugin(InertiaPlugin);
    registeredPlugins.push('InertiaPlugin');
  }
  if (typeof Observer !== 'undefined') {
    gsap.registerPlugin(Observer);
    registeredPlugins.push('Observer');
  }
  if (typeof ScrambleTextPlugin !== 'undefined') {
    gsap.registerPlugin(ScrambleTextPlugin);
    registeredPlugins.push('ScrambleTextPlugin');
  }
  if (typeof SplitText !== 'undefined') {
    gsap.registerPlugin(SplitText);
    registeredPlugins.push('SplitText');
  }

  // Signature neo-brutalist custom bezier curves
  if (typeof CustomEase !== 'undefined') {
    CustomEase.create('brutalPunch', 'M0,0 C0.05,0.9 0.1,1.05 1,1');
    CustomEase.create('brutalDrop', 'M0,0 C0.16,1 0.3,1 1,1');
    CustomEase.create('elasticSnap', 'M0,0 C0.175,0.885 0.32,1.275 1,1');
    CustomEase.create('brutalShutter', 'M0,0 C0.15,0 0.05,1 1,1');
  }

  // Signature physics wiggles
  if (typeof CustomWiggle !== 'undefined') {
    CustomWiggle.create('brutalShake', { wiggles: 5, type: 'uniform' });
    CustomWiggle.create('glitchJitter', { wiggles: 8, type: 'random' });
  }

  // Accessibility: Respect reduced motion preference
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  document.addEventListener('DOMContentLoaded', () => {
    // 1. Shutter Blade Aperture Transition (Opening on load)
    initShutterEntrance();
    initShutterNavigationLinks();

    // 2. Custom Neo-Brutalist Slide Progress Indicator (Placed right below navbar border)
    initCustomSlideIndicator();

    if (prefersReducedMotion) return;

    // 2. Custom Neo-Brutalist Difference Crosshair Cursor & Magnetic Gravitation
    initBrutalistCursorAndMagnetics();

    // 3. Scroll Velocity Skew Physics & Dynamic Marquee Turbo
    initScrollVelocityPhysics();

    // 4. Audio-Reactive Equalizer Visualizers
    initAudioEqualizerMonitors();

    // 5. Page-Specific Motion Engines
    const isDownloadPage = document.body.classList.contains('download-page-body');
    if (isDownloadPage) {
      initDownloadPageKinetic();
    } else {
      initHeroTitleProximityGlitch();
      initIndexPageKinetic();
      initMobileShowcaseStage();
    }

    // 6. Interactive 3D Brutalist Card Tilt & Scramble Hovers
    initBrutalist3DTiltPhysics();
    initCyberScrambleHover();
  });

  /* =========================================================================
     1. Neo-Brutalist Aperture Shutter Blade Page Transition
     ========================================================================= */
  function initShutterEntrance() {
    const shutter = document.getElementById('groovd-shutter');
    if (!shutter) return;

    const blades = shutter.querySelectorAll('.shutter-blade');
    const badge = shutter.querySelector('.shutter-badge');

    // Only animate entrance if arriving from an internal page transition
    const wasTransitioning = sessionStorage.getItem('groovd_shutter_active') === '1';
    sessionStorage.removeItem('groovd_shutter_active');

    if (!wasTransitioning) {
      // Keep shutter retracted and inactive
      gsap.set([blades[0], blades[2]], { y: '-101%' });
      gsap.set([blades[1], blades[3]], { y: '101%' });
      if (badge) gsap.set(badge, { opacity: 0 });
      shutter.classList.remove('is-active');
      return;
    }

    shutter.classList.add('is-active');
    gsap.set(blades[0], { y: '0%' });
    gsap.set(blades[1], { y: '0%' });
    gsap.set(blades[2], { y: '0%' });
    gsap.set(blades[3], { y: '0%' });
    if (badge) gsap.set(badge, { opacity: 1, scale: 1 });

    const tl = gsap.timeline({
      delay: 0.05,
      onComplete: () => {
        shutter.classList.remove('is-active');
      }
    });

    if (badge) {
      tl.to(badge, {
        opacity: 0,
        scale: 0.9,
        duration: 0.22,
        ease: 'power2.in'
      });
    }

    // Blades 1 & 3 slide up, blades 2 & 4 slide down
    tl.to([blades[0], blades[2]], {
      y: '-101%',
      duration: 0.5,
      stagger: 0.04,
      ease: 'power4.inOut'
    }, '-=0.08');

    tl.to([blades[1], blades[3]], {
      y: '101%',
      duration: 0.5,
      stagger: 0.04,
      ease: 'power4.inOut'
    }, '<');
  }

  function initShutterNavigationLinks() {
    const shutter = document.getElementById('groovd-shutter');
    if (!shutter) return;

    const blades = shutter.querySelectorAll('.shutter-blade');
    const badge = shutter.querySelector('.shutter-badge');
    const badgeText = shutter.querySelector('.shutter-badge-text');

    // Intercept internal page navigation links
    const internalLinks = document.querySelectorAll(
      'a[href="download.html"], a[href="index.html"], .btn-primary-download, .btn-nav-download, .btn-sticky-download, .btn-nav-return'
    );

    internalLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        const targetHref = link.getAttribute('href');
        if (!targetHref || targetHref.startsWith('#')) return;

        // Allow middle clicks or ctrl/cmd clicks to open in new tab
        if (e.metaKey || e.ctrlKey || e.button !== 0) return;

        e.preventDefault();
        try {
          sessionStorage.setItem('groovd_shutter_active', '1');
        } catch (err) {
          // Fallback if cookies/storage blocked
        }
        shutter.classList.add('is-active');

        const destination = targetHref.includes('download') ? 'DOWNLOAD PORTAL' : 'MAIN ARCHIVE';
        if (badgeText && typeof ScrambleTextPlugin !== 'undefined') {
          gsap.to(badgeText, {
            scrambleText: {
              text: `ROUTING // ${destination}`,
              chars: '01_//[]{}X#!',
              speed: 0.5
            },
            duration: 0.25
          });
        }

        const tl = gsap.timeline({
          onComplete: () => {
            window.location.href = targetHref;
          }
        });

        // Slam blades shut from opposite directions
        tl.fromTo([blades[0], blades[2]], 
          { y: '-101%' },
          { y: '0%', duration: 0.35, stagger: 0.04, ease: 'brutalPunch' }
        );

        tl.fromTo([blades[1], blades[3]], 
          { y: '101%' },
          { y: '0%', duration: 0.35, stagger: 0.04, ease: 'brutalPunch' },
          '<'
        );

        if (badge) {
          tl.to(badge, {
            opacity: 1,
            scale: 1,
            duration: 0.2,
            ease: 'brutalPunch'
          }, '-=0.15');
        }
      });
    });
  }

  /* =========================================================================
     2. Neo-Brutalist Block Cursor & Magnetic Gravitation
     ========================================================================= */
  function initBrutalistCursorAndMagnetics() {
    const cursor = document.getElementById('groovd-cursor');
    if (!cursor) return;

    // Only enable on desktop mouse pointers
    if (window.matchMedia('(pointer: coarse)').matches) {
      cursor.style.display = 'none';
      return;
    }

    gsap.set(cursor, { xPercent: -50, yPercent: -50, opacity: 0 });

    const xTo = gsap.quickTo(cursor, 'x', { duration: 0.02, ease: 'none' });
    const yTo = gsap.quickTo(cursor, 'y', { duration: 0.02, ease: 'none' });

    let isVisible = false;
    window.addEventListener('mousemove', (e) => {
      if (!isVisible) {
        isVisible = true;
        gsap.to(cursor, { opacity: 1, duration: 0.15 });
      }
      xTo(e.clientX);
      yTo(e.clientY);
    });

    window.addEventListener('mouseleave', () => {
      isVisible = false;
      gsap.to(cursor, { opacity: 0, duration: 0.15 });
    });

    window.addEventListener('mousedown', () => {
      cursor.classList.add('cursor-active');
    });
    window.addEventListener('mouseup', () => {
      cursor.classList.remove('cursor-active');
    });

    // Interactive Hover Magnetics & Block Expansion
    const magneticButtons = document.querySelectorAll(
      '.btn-primary-download, .btn-secondary-guide, .btn-action-download, .btn-action-guide, .btn-nav-return, .btn-nav-download, .btn-sticky-download, .btn-copy-checksum, .btn-qr-action, .nav-links a, .footer-nav-bar a'
    );

    magneticButtons.forEach(btn => {
      let bounds = null;

      btn.addEventListener('mouseenter', () => {
        bounds = btn.getBoundingClientRect();
        cursor.classList.add('cursor-hover-interactive');
      });

      btn.addEventListener('mousemove', (e) => {
        if (!bounds) bounds = btn.getBoundingClientRect();
        const mouseX = e.clientX - bounds.left;
        const mouseY = e.clientY - bounds.top;
        const dx = (mouseX / bounds.width - 0.5) * 2;
        const dy = (mouseY / bounds.height - 0.5) * 2;

        gsap.to(btn, {
          x: dx * 8,
          y: dy * 6,
          duration: 0.15,
          ease: 'power1.out',
          overwrite: 'auto'
        });
      });

      btn.addEventListener('mouseleave', () => {
        bounds = null;
        cursor.classList.remove('cursor-hover-interactive');
        gsap.to(btn, {
          x: 0,
          y: 0,
          duration: 0.45,
          ease: 'elasticSnap',
          overwrite: 'auto'
        });
      });
    });

    // Card, Cover & Input Hover Block Expansion
    const interactiveCards = document.querySelectorAll(
      '.feature-card, .showcase-card, .dossier-card, .qr-card, .step-card, .rating-demo-card, .covers-track img, input[type="range"]'
    );

    interactiveCards.forEach(card => {
      card.addEventListener('mouseenter', () => {
        cursor.classList.add('cursor-hover-interactive');
      });

      card.addEventListener('mouseleave', () => {
        cursor.classList.remove('cursor-hover-interactive');
      });
    });
  }

  /* =========================================================================
     3. Scroll Velocity Skew Physics (Marquees remain continuous & constant)
     ========================================================================= */
  function initScrollVelocityPhysics() {
    if (typeof ScrollTrigger === 'undefined') return;

    const skewTargets = document.querySelectorAll(
      '.hero-title, .showcase-card, .dossier-card, .qr-card, .step-card, .specs-table-wrapper'
    );

    let skewSetter = null;
    if (skewTargets.length > 0) {
      skewSetter = gsap.quickTo(skewTargets, 'skewY', {
        duration: 0.25,
        ease: 'power2.out'
      });
    }

    ScrollTrigger.create({
      onUpdate: (self) => {
        const velocity = self.getVelocity(); // Pixels per second
        
        // Kinetic Skew on Content
        if (skewSetter) {
          const clampedSkew = Math.max(-2.5, Math.min(2.5, velocity / 450));
          skewSetter(clampedSkew);
        }
      }
    });

    // Reset skew when scrolling stops
    ScrollTrigger.addEventListener('scrollEnd', () => {
      if (skewSetter) {
        skewSetter(0);
      }
    });
  }

  /* =========================================================================
     4. Audio-Reactive Equalizer Hardware Visualizer
     ========================================================================= */
  function initAudioEqualizerMonitors() {
    // 1. Hero Audio Equalizer Monitor (Polyrhythmic loop)
    const heroEqBars = document.querySelectorAll('.hero-eq-bars .eq-bar');
    if (heroEqBars.length > 0) {
      heroEqBars.forEach((bar, index) => {
        const delay = (index % 4) * 0.08;
        const duration = 0.18 + (index % 3) * 0.06;

        function animateBar() {
          const targetHeight = 20 + Math.random() * 80;
          gsap.to(bar, {
            height: `${targetHeight}%`,
            duration: duration,
            ease: 'power1.inOut',
            onComplete: animateBar
          });
        }
        setTimeout(animateBar, delay * 1000);
      });
    }
  }

  /* =========================================================================
     5. Homepage (Index) Kinetic Motion Suite
     ========================================================================= */
  function initIndexPageKinetic() {
    const splash = document.getElementById('splash-screen');

    let heroTriggered = false;
    function triggerHeroSequence() {
      if (heroTriggered) return;
      heroTriggered = true;

      const tl = gsap.timeline({ defaults: { ease: 'brutalPunch' } });

      // 1. Navbar slide down
      tl.from('.site-nav', {
        y: -30,
        opacity: 0,
        duration: 0.4
      }, 0);



      // 3. Hero Headline 3D Stamp Flip
      const glitchChars = document.querySelectorAll('.hero-glitch-char');
      if (glitchChars.length > 0) {
        tl.from(glitchChars, {
          y: 40,
          opacity: 0,
          rotateX: -75,
          stagger: 0.015,
          duration: 0.45,
          ease: 'brutalPunch'
        }, 0.08);
      } else {
        tl.from('.hero-title-line', {
          y: 35,
          opacity: 0,
          stagger: 0.08,
          duration: 0.5
        }, 0.08);
      }

      // 4. Subtitle Matrix Unblur
      tl.fromTo('.hero-subtitle', 
        { y: 20, opacity: 0, filter: 'blur(4px)' },
        { y: 0, opacity: 1, filter: 'blur(0px)', duration: 0.45, ease: 'power2.out' },
        0.22
      );

      // 5. Hero Actions Hard Shadow Snap
      tl.from('.hero-actions-container', {
        y: 20,
        opacity: 0,
        scale: 0.96,
        duration: 0.45
      }, 0.3);
    }

    // Sequence after in-app splash screen
    if (splash) {
      const observer = new MutationObserver(() => {
        if (splash.classList.contains('splash-fade-out') || !document.body.contains(splash)) {
          observer.disconnect();
          triggerHeroSequence();
        }
      });
      observer.observe(splash, { attributes: true, attributeFilter: ['class'] });

      splash.addEventListener('click', () => {
        setTimeout(triggerHeroSequence, 350);
      }, { once: true });

      setTimeout(triggerHeroSequence, 2300);
    } else {
      triggerHeroSequence();
    }

    if (typeof ScrollTrigger !== 'undefined') {
      // Background Covers Wall Scroll Parallax
      const coversWall = document.querySelector('.hero-covers-bg');
      if (coversWall) {
        gsap.to(coversWall, {
          scrollTrigger: {
            trigger: '#hero',
            start: 'top top',
            end: 'bottom top',
            scrub: 1
          },
          y: -80,
          scale: 1.05,
          opacity: 0.14
        });
      }

      // Section Headings 3D SplitText Mechanical Stagger
      initSectionHeadingsSplit();

      // Feature Cards Clean Mechanical Entrance
      const featureCards = document.querySelectorAll('.feature-card');
      if (featureCards.length > 0) {
        gsap.from(featureCards, {
          scrollTrigger: {
            trigger: '#features',
            start: 'top 85%',
            toggleActions: 'play none none none'
          },
          y: 20,
          opacity: 0,
          scale: 0.98,
          stagger: 0.08,
          duration: 0.5,
          ease: 'power2.out',
          clearProps: 'all'
        });
      }

      // Interactive Rating Dial Playground Reveal
      const ratingCard = document.getElementById('demo-rating-card');
      if (ratingCard) {
        gsap.from(ratingCard, {
          scrollTrigger: {
            trigger: '#rating-demo',
            start: 'top 78%',
            toggleActions: 'play none none none',
            onEnter: () => {
              animateRatingScoreCounter();
            }
          },
          y: 70,
          rotateX: 20,
          scale: 0.92,
          opacity: 0,
          boxShadow: '0px 0px 0px #000000',
          duration: 0.85,
          ease: 'brutalPunch',
          clearProps: 'rotateX'
        });
      }

      // Showcase Cards 3D Deck Stamp
      const showcaseCards = document.querySelectorAll('.showcase-card');
      if (showcaseCards.length > 0) {
        gsap.from(showcaseCards, {
          scrollTrigger: {
            trigger: '#showcase',
            start: 'top 78%',
            toggleActions: 'play none none none'
          },
          y: 75,
          rotateX: 22,
          scale: 0.92,
          opacity: 0,
          boxShadow: '0px 0px 0px #000000',
          stagger: 0.14,
          duration: 0.8,
          ease: 'brutalPunch',
          clearProps: 'rotateX'
        });
      }

      // Sideload Step Items Accordion Reveal
      const stepItems = document.querySelectorAll('.step-item');
      if (stepItems.length > 0) {
        gsap.from(stepItems, {
          scrollTrigger: {
            trigger: '#install-guide',
            start: 'top 80%',
            toggleActions: 'play none none none'
          },
          x: -40,
          rotateY: -15,
          opacity: 0,
          stagger: 0.12,
          duration: 0.7,
          ease: 'brutalDrop',
          clearProps: 'rotateY'
        });
      }

      // Specs Table Mechanical Stamp
      const specsTable = document.querySelector('.specs-table-wrapper');
      if (specsTable) {
        gsap.from(specsTable, {
          scrollTrigger: {
            trigger: '#specs',
            start: 'top 82%',
            toggleActions: 'play none none none'
          },
          y: 50,
          scale: 0.95,
          opacity: 0,
          duration: 0.75,
          ease: 'brutalPunch'
        });
      }

      // Monumental Footer SVG Tracking Reveal
      initFooterKinetic();
    }

    // Connect slider reactive physics to slider element
    initSliderInteractiveReactor();
  }

  // Section Headings 3D SplitText Mechanical Reveal
  function initSectionHeadingsSplit() {
    if (typeof SplitText === 'undefined') return;

    const headings = document.querySelectorAll('.section-title');
    headings.forEach(heading => {
      const split = new SplitText(heading, { type: 'chars,words', charsClass: 'char-split' });
      gsap.from(split.chars, {
        scrollTrigger: {
          trigger: heading,
          start: 'top 85%',
          toggleActions: 'play none none none'
        },
        y: 40,
        opacity: 0,
        rotateX: -85,
        stagger: 0.02,
        duration: 0.65,
        ease: 'brutalPunch'
      });
    });
  }

  // Animated Numeric Counter on Rating Score
  function animateRatingScoreCounter() {
    const scoreVal = document.getElementById('demo-score-value');
    if (!scoreVal) return;
    const targetVal = parseFloat(scoreVal.textContent) || 9.6;

    const counterObj = { val: 0.0 };
    gsap.to(counterObj, {
      val: targetVal,
      duration: 1.2,
      ease: 'power3.out',
      onUpdate: () => {
        scoreVal.textContent = counterObj.val.toFixed(1);
      }
    });
  }

  // Slider Drag Reactive Physics & Oscilloscope Reactor
  function initSliderInteractiveReactor() {
    const slider = document.getElementById('demo-rating-slider');
    const scoreVal = document.getElementById('demo-score-value');
    const descriptor = document.getElementById('demo-descriptor');
    const spikeSign = document.getElementById('demo-spike-sign');
    const ratingCard = document.getElementById('demo-rating-card');
    const spectrumBars = document.querySelectorAll('#osc-spectrum-bars .spectrum-bar');
    const oscTag = document.getElementById('osc-status-tag');

    if (!slider || !scoreVal || !descriptor) return;

    let previousScore = parseFloat(slider.value) || 9.6;

    slider.addEventListener('input', () => {
      const currentScore = parseFloat(slider.value) || 0;

      // 1. Score number scale pop
      gsap.to(scoreVal, {
        scale: 1.18,
        duration: 0.08,
        ease: 'power1.out',
        overwrite: 'auto',
        onComplete: () => {
          gsap.to(scoreVal, { scale: 1.0, duration: 0.22, ease: 'elasticSnap' });
        }
      });

      // 2. Descriptor chip flip
      gsap.fromTo(descriptor,
        { scale: 0.92 },
        { scale: 1.0, duration: 0.2, ease: 'brutalPunch', overwrite: 'auto' }
      );

      // 3. Pulse on spike sign
      if (spikeSign && currentScore >= 8.5) {
        gsap.fromTo(spikeSign,
          { filter: 'drop-shadow(0 0 10px rgba(204,255,0,0.9))' },
          { filter: 'drop-shadow(0 0 0px rgba(204,255,0,0))', duration: 0.35, ease: 'power2.out' }
        );
      }

      // 4. Reactive Oscilloscope Equalizer Spectrum
      if (spectrumBars.length > 0) {
        const normalizedScore = currentScore / 10.0; // 0 to 1
        spectrumBars.forEach((bar, i) => {
          // Calculate dynamic wave curve
          const wave = Math.sin((i / spectrumBars.length) * Math.PI) * 0.5 + 0.5;
          const jitter = (Math.random() - 0.5) * 0.2;
          const barHeight = Math.max(12, Math.min(100, (normalizedScore * wave * 100) + (jitter * 30)));

          bar.style.height = `${barHeight.toFixed(0)}%`;

          if (currentScore >= 9.6) {
            bar.className = 'spectrum-bar active spike-peak';
          } else if (currentScore >= 7.0) {
            bar.className = 'spectrum-bar active';
          } else {
            bar.className = 'spectrum-bar';
          }
        });

        if (oscTag) {
          if (currentScore >= 9.6) {
            oscTag.textContent = `CRITICAL SPIKE // ${currentScore.toFixed(1)}`;
            oscTag.style.color = '#CCFF00';
          } else if (currentScore <= 2.5) {
            oscTag.textContent = `NOISE MURMUR // ${currentScore.toFixed(1)}`;
            oscTag.style.color = '#FF3B30';
          } else {
            oscTag.textContent = `DYNAMIC SPECTRUM // ${currentScore.toFixed(1)}`;
            oscTag.style.color = '#FFFFFF';
          }
        }
      }

      // 5. Brutalist Screen-Shake on 10.0 Milestone / Whole Number Impact
      if (currentScore === 10.0 && previousScore !== 10.0) {
        if (typeof CustomWiggle !== 'undefined' && ratingCard) {
          gsap.to(ratingCard, {
            x: 6,
            duration: 0.35,
            ease: 'brutalShake',
            clearProps: 'x'
          });
        }
      }

      previousScore = currentScore;
    });
  }

  /* =========================================================================
     6. Download Page Kinetic Motion Suite
     ========================================================================= */
  function initDownloadPageKinetic() {
    const tl = gsap.timeline({ defaults: { ease: 'brutalPunch' } });

    // 1. Navigation Slide Down
    tl.from('.site-nav', {
      y: -30,
      opacity: 0,
      duration: 0.4
    }, 0);

    // 2. Portal Header Badges Scramble (concurrent)
    const badgeCodes = document.querySelectorAll('.portal-badge-code, .portal-badge-version');
    if (typeof ScrambleTextPlugin !== 'undefined' && badgeCodes.length > 0) {
      badgeCodes.forEach(b => {
        const text = b.textContent;
        gsap.to(b, {
          scrambleText: { text, chars: '01_//[]{}X#!', speed: 0.6 },
          duration: 0.45,
          delay: 0.08
        });
      });
    }

    // 3. Portal Title Character Stamp Flip
    const portalTitle = document.querySelector('.portal-title');
    if (portalTitle && typeof SplitText !== 'undefined') {
      const split = new SplitText(portalTitle, { type: 'words,chars', charsClass: 'char-split', wordsClass: 'word-split' });
      tl.from(split.chars, {
        y: 40,
        opacity: 0,
        rotateX: -75,
        stagger: 0.012,
        duration: 0.45,
        ease: 'brutalPunch'
      }, 0.08);
    } else {
      tl.from('.portal-title', {
        y: 30,
        opacity: 0,
        duration: 0.45
      }, 0.08);
    }

    tl.from('.portal-subtitle', {
      y: 15,
      opacity: 0,
      duration: 0.35
    }, 0.2);

    // 4. Central Download Command Center Card Slam
    tl.from('.download-action-card', {
      y: 40,
      opacity: 0,
      scale: 0.96,
      boxShadow: '0px 0px 0px #000000',
      duration: 0.5,
      ease: 'brutalPunch'
    }, 0.22);

    // 5. Two-Column Dossier & QR Cards Stagger
    tl.from('.dossier-card', {
      x: -40,
      rotateY: 10,
      opacity: 0,
      duration: 0.5,
      ease: 'brutalPunch',
      clearProps: 'rotateY'
    }, 0.3);

    tl.from('.qr-card', {
      x: 40,
      rotateY: -10,
      opacity: 0,
      duration: 0.5,
      ease: 'brutalPunch',
      clearProps: 'rotateY'
    }, 0.3);

    // 7. Quick Sideload Step Cards
    if (typeof ScrollTrigger !== 'undefined') {
      const stepCards = document.querySelectorAll('.step-card');
      if (stepCards.length > 0) {
        gsap.from(stepCards, {
          scrollTrigger: {
            trigger: '.quick-steps-section',
            start: 'top 80%',
            toggleActions: 'play none none none'
          },
          y: 50,
          rotateX: 20,
          opacity: 0,
          stagger: 0.15,
          duration: 0.7,
          ease: 'brutalPunch',
          clearProps: 'rotateX'
        });
      }

      initFooterKinetic();
    }

    // 8. Terminal Download Handshake with Real-Time Data Throughput Ticker
    initTerminalDownloadHandshake();
  }

  // Multi-Phase Terminal Handshake Sequence on Download Page
  function initTerminalDownloadHandshake() {
    const statusText = document.getElementById('status-text');
    const statusDot = document.getElementById('status-dot');
    const meterBar = document.getElementById('download-meter-bar');
    const streamBytes = document.getElementById('stream-bytes');
    const streamSpeed = document.getElementById('stream-speed');
    const streamCipher = document.getElementById('stream-cipher');

    if (!statusText || !meterBar) return;

    // Phase 1: 0ms Handshake
    if (typeof ScrambleTextPlugin !== 'undefined') {
      gsap.to(statusText, {
        scrambleText: {
          text: '[01/03] INITIATING SECURE ARCHIVE HANDSHAKE...',
          chars: '01_//[]{}#*^!',
          speed: 0.5
        },
        duration: 0.6
      });
    }

    // Animate Data Throughput Counter (0.0 MB -> 66.5 MB)
    const byteCounter = { val: 0.0 };
    gsap.to(byteCounter, {
      val: 66.5,
      duration: 1.4,
      ease: 'power2.out',
      onUpdate: () => {
        if (streamBytes) {
          streamBytes.textContent = `${byteCounter.val.toFixed(1)} MB`;
        }
      }
    });

    // Speed fluctuation
    if (streamSpeed) {
      setTimeout(() => { streamSpeed.textContent = '19.4 MB/S'; }, 400);
      setTimeout(() => { streamSpeed.textContent = '24.2 MB/S'; }, 900);
      setTimeout(() => { streamSpeed.textContent = '18.1 MB/S'; }, 1300);
    }

    // Phase 2: 700ms Integrity Verification
    setTimeout(() => {
      if (typeof ScrambleTextPlugin !== 'undefined') {
        gsap.to(statusText, {
          scrambleText: {
            text: '[02/03] VALIDATING SHA-256 INTEGRITY FINGERPRINT...',
            chars: '01_//[]{}#*^!',
            speed: 0.5
          },
          duration: 0.55
        });
      }
      if (streamCipher) {
        streamCipher.textContent = 'SHA-256 VALIDATED';
        streamCipher.style.color = '#CCFF00';
      }
      meterBar.style.width = '70%';
    }, 700);

    // Phase 3: 1350ms Dispatch
    setTimeout(() => {
      if (typeof ScrambleTextPlugin !== 'undefined') {
        gsap.to(statusText, {
          scrambleText: {
            text: '[03/03] DISPATCHING OFFICIAL APK TO BROWSER',
            chars: '01_//[]{}#*^!',
            speed: 0.4
          },
          duration: 0.55
        });
      } else {
        statusText.textContent = 'DOWNLOAD DISPATCHED // CHECK NOTIFICATIONS';
      }
      meterBar.style.width = '100%';
      if (statusDot) {
        statusDot.classList.add('status-active');
        gsap.fromTo(statusDot,
          { scale: 2.0, filter: 'drop-shadow(0 0 16px #CCFF00)' },
          { scale: 1.0, filter: 'drop-shadow(0 0 8px #CCFF00)', duration: 0.5, ease: 'elasticSnap' }
        );
      }
    }, 1350);

    // Enhanced Copy Checksum with Cyber-Scramble
    const copyBtn = document.getElementById('btn-copy-checksum');
    const copyLabel = document.getElementById('copy-btn-label');
    if (copyBtn && copyLabel && typeof ScrambleTextPlugin !== 'undefined') {
      copyBtn.addEventListener('click', () => {
        gsap.to(copyLabel, {
          scrambleText: { text: '[COPIED]', chars: '01#X!' },
          duration: 0.3
        });
        setTimeout(() => {
          gsap.to(copyLabel, {
            scrambleText: { text: 'COPY', chars: '01#X!' },
            duration: 0.3
          });
        }, 2200);
      });
    }
  }

  /* =========================================================================
     7. Monumental Footer SVG Kinetic Reveal
     ========================================================================= */
  function initFooterKinetic() {
    const footerSvgText = document.querySelector('.footer-svg-text');
    const footerSvgSquare = document.querySelector('.footer-svg-square');

    if (footerSvgText && typeof ScrollTrigger !== 'undefined') {
      // Expansive tracking slide-in
      gsap.from(footerSvgText, {
        scrollTrigger: {
          trigger: '.site-footer',
          start: 'top 85%',
          toggleActions: 'play none none none'
        },
        y: 45,
        opacity: 0,
        letterSpacing: '-18px',
        duration: 1.0,
        ease: 'power3.out'
      });

      // Acid lime square drop bounce
      if (footerSvgSquare) {
        gsap.from(footerSvgSquare, {
          scrollTrigger: {
            trigger: '.site-footer',
            start: 'top 85%',
            toggleActions: 'play none none none'
          },
          y: -60,
          opacity: 0,
          delay: 0.3,
          duration: 0.75,
          ease: 'bounce.out'
        });
      }
    }
  }

  /* =========================================================================
     8. Interactive 3D Brutalist Card Tilt Physics
     ========================================================================= */
  function initBrutalist3DTiltPhysics() {
    if (window.innerWidth < 960) return;

    const tiltCards = document.querySelectorAll(
      '.feature-card, .showcase-card, .download-action-card, .dossier-card, .qr-card, .step-card, .rating-demo-card'
    );

    tiltCards.forEach(card => {
      let bounds = null;

      card.addEventListener('mouseenter', () => {
        bounds = card.getBoundingClientRect();
      });

      card.addEventListener('mousemove', (e) => {
        if (!bounds) bounds = card.getBoundingClientRect();
        const mouseX = e.clientX - bounds.left;
        const mouseY = e.clientY - bounds.top;

        const dx = (mouseX / bounds.width - 0.5) * 2;
        const dy = (mouseY / bounds.height - 0.5) * 2;

        const tiltX = -dy * 5.5; // Max 5.5 deg pitch
        const tiltY = dx * 5.5;  // Max 5.5 deg roll
        const shadowX = 6 - (dx * 6);
        const shadowY = 6 - (dy * 6);

        gsap.to(card, {
          rotateX: tiltX,
          rotateY: tiltY,
          transformPerspective: 900,
          boxShadow: `${shadowX.toFixed(1)}px ${shadowY.toFixed(1)}px 0px #000000`,
          duration: 0.15,
          ease: 'power1.out'
        });
      });

      card.addEventListener('mouseleave', () => {
        bounds = null;
        gsap.to(card, {
          rotateX: 0,
          rotateY: 0,
          boxShadow: '6px 6px 0px #000000',
          duration: 0.45,
          ease: 'brutalPunch'
        });
      });
    });
  }

  /* =========================================================================
     9. Cyber / Brutalist Scramble on Hover
     ========================================================================= */
  function initCyberScrambleHover() {
    if (typeof ScrambleTextPlugin === 'undefined') return;

    const interactiveLinks = document.querySelectorAll(
      '.nav-links a, .footer-nav-bar a, .btn-nav-return, .card-kicker, .section-label, .steps-badge, .footer-badge'
    );

    interactiveLinks.forEach(el => {
      const originalText = el.textContent.trim();
      let isScrambling = false;

      el.addEventListener('mouseenter', () => {
        if (isScrambling) return;
        isScrambling = true;

        gsap.to(el, {
          scrambleText: {
            text: originalText,
            chars: '!<>-_\\/[]{}—=+*^?#01',
            speed: 0.35
          },
          duration: 0.35,
          ease: 'none',
          onComplete: () => {
            isScrambling = false;
          }
        });
      });
    });
  }

  /* =========================================================================
     10. Hero Headline Proximity Glitch Engine & Cursor HUD
     When cursor hits "UNCOMPROMISING MUSIC ARCHIVE.", letters near the cursor
     cycle rapid neo-brutalist glyphs in a continuous loop until cursor leaves.
     ========================================================================= */
  function initHeroTitleProximityGlitch() {
    const heroTitle = document.getElementById('hero-title');
    if (!heroTitle) return;

    const hudBadge = document.getElementById('cursor-title-hud');
    const lines = heroTitle.querySelectorAll('.hero-title-line');
    if (lines.length === 0) return;

    const GLITCH_GLYPHS = '!<>-_\\/[]{}—=+*^?#01X$%@';
    const PROXIMITY_RADIUS = 95; // Radius around cursor where letters scramble
    const allChars = [];

    // Wrap each character in .hero-glitch-char while preserving lines and spacing
    lines.forEach(line => {
      const rawText = line.textContent.trim();
      line.innerHTML = '';
      for (let i = 0; i < rawText.length; i++) {
        const char = rawText[i];
        if (char === ' ') {
          const spaceSpan = document.createElement('span');
          spaceSpan.className = 'hero-char-space';
          spaceSpan.innerHTML = '&nbsp;';
          line.appendChild(spaceSpan);
        } else {
          const charSpan = document.createElement('span');
          charSpan.className = 'hero-glitch-char';
          charSpan.dataset.char = char;
          charSpan.textContent = char;
          line.appendChild(charSpan);
          allChars.push({
            el: charSpan,
            orig: char,
            rect: null
          });
        }
      }
    });

    let isHovering = false;
    let mouseX = -9999;
    let mouseY = -9999;
    let glitchInterval = null;
    let hudInterval = null;

    function updateCharRects() {
      allChars.forEach(item => {
        const r = item.el.getBoundingClientRect();
        item.rect = {
          centerX: r.left + r.width / 2,
          centerY: r.top + r.height / 2
        };
      });
    }

    const hudPhrases = [
      '[ ARCHIVE // RAW ]',
      '[ 10.0 // DECIMAL ]',
      '[ CANON // CRITIC ]',
      '[ UNCOMPROMISING ]'
    ];
    let hudPhraseIdx = 0;

    function startGlitchLoop() {
      if (glitchInterval) return;
      updateCharRects();

      if (hudBadge) {
        hudBadge.classList.add('is-visible');
        hudBadge.textContent = hudPhrases[0];
      }

      // Loop glitch on proximity characters every 45ms
      glitchInterval = setInterval(() => {
        allChars.forEach(item => {
          if (!item.rect) return;
          const dist = Math.hypot(mouseX - item.rect.centerX, mouseY - item.rect.centerY);

          if (dist < PROXIMITY_RADIUS) {
            // Character is within proximity of the cursor: cycle cyber glyphs
            item.el.classList.add('is-glitching');
            const randomGlyph = GLITCH_GLYPHS[Math.floor(Math.random() * GLITCH_GLYPHS.length)];
            item.el.textContent = randomGlyph;
          } else {
            // Outside proximity radius: restore original character
            if (item.el.textContent !== item.orig) {
              item.el.textContent = item.orig;
              item.el.classList.remove('is-glitching');
            }
          }
        });
      }, 45);

      // Loop HUD badge scramble
      if (hudBadge && typeof ScrambleTextPlugin !== 'undefined') {
        hudInterval = setInterval(() => {
          hudPhraseIdx = (hudPhraseIdx + 1) % hudPhrases.length;
          gsap.to(hudBadge, {
            scrambleText: {
              text: hudPhrases[hudPhraseIdx],
              chars: '!<>-_\\/[]{}—=+*^?#01',
              speed: 0.4
            },
            duration: 0.35,
            ease: 'none'
          });
        }, 850);
      }
    }

    function stopGlitchLoop() {
      if (glitchInterval) {
        clearInterval(glitchInterval);
        glitchInterval = null;
      }
      if (hudInterval) {
        clearInterval(hudInterval);
        hudInterval = null;
      }

      // Restore all characters immediately
      allChars.forEach(item => {
        item.el.textContent = item.orig;
        item.el.classList.remove('is-glitching');
      });

      if (hudBadge) {
        hudBadge.classList.remove('is-visible');
      }
    }

    heroTitle.addEventListener('mouseenter', (e) => {
      isHovering = true;
      mouseX = e.clientX;
      mouseY = e.clientY;
      startGlitchLoop();
    });

    heroTitle.addEventListener('mousemove', (e) => {
      mouseX = e.clientX;
      mouseY = e.clientY;
      if (!isHovering) {
        isHovering = true;
        startGlitchLoop();
      }
    });

    heroTitle.addEventListener('mouseleave', () => {
      isHovering = false;
      mouseX = -9999;
      mouseY = -9999;
      stopGlitchLoop();
    });

    window.addEventListener('resize', () => {
      if (isHovering) updateCharRects();
    });

    window.addEventListener('scroll', () => {
      if (isHovering) updateCharRects();
    }, { passive: true });
  }

  /* =========================================================================
     Custom Neo-Brutalist Slide Progress Indicator (Navbar Border Tracking)
     ========================================================================= */
  function initCustomSlideIndicator() {
    const indicator = document.getElementById('nav-slide-indicator');
    const fill = document.getElementById('nav-slide-fill');
    if (!indicator || !fill) return;

    function getScrollProgress() {
      const doc = document.documentElement;
      const body = document.body;
      const scrollTop = window.pageYOffset || doc.scrollTop || body.scrollTop || 0;
      const scrollHeight = Math.max(
        body.scrollHeight,
        doc.scrollHeight,
        body.offsetHeight,
        doc.offsetHeight,
        body.clientHeight,
        doc.clientHeight
      );
      const clientHeight = window.innerHeight || doc.clientHeight || 1;
      const maxScroll = Math.max(1, scrollHeight - clientHeight);
      return Math.min(1, Math.max(0, scrollTop / maxScroll));
    }

    let isTicking = false;
    function updateProgress() {
      const progress = getScrollProgress();
      fill.style.transform = `scaleX(${progress})`;
      indicator.setAttribute('aria-valuenow', Math.round(progress * 100));
    }

    function onScrollOrResize() {
      if (!isTicking) {
        requestAnimationFrame(() => {
          updateProgress();
          isTicking = false;
        });
        isTicking = true;
      }
    }

    window.addEventListener('scroll', onScrollOrResize, { passive: true });
    window.addEventListener('resize', onScrollOrResize, { passive: true });

    if (typeof ScrollTrigger !== 'undefined') {
      ScrollTrigger.addEventListener('refresh', updateProgress);
    }

    // Initial update
    updateProgress();

    // Tactile scrub / click seeking along the slide track
    function seekFromEvent(e) {
      const rect = indicator.getBoundingClientRect();
      const clientX = e.clientX !== undefined ? e.clientX : (e.touches && e.touches[0] ? e.touches[0].clientX : 0);
      const relativeX = Math.max(0, Math.min(rect.width, clientX - rect.left));
      const targetRatio = rect.width > 0 ? (relativeX / rect.width) : 0;

      const doc = document.documentElement;
      const body = document.body;
      const scrollHeight = Math.max(body.scrollHeight, doc.scrollHeight);
      const clientHeight = window.innerHeight || doc.clientHeight || 1;
      const maxScroll = Math.max(1, scrollHeight - clientHeight);
      const targetScroll = targetRatio * maxScroll;

      window.scrollTo({
        top: targetScroll,
        behavior: 'auto'
      });
      updateProgress();
    }

    let isDragging = false;

    indicator.addEventListener('pointerdown', (e) => {
      isDragging = true;
      indicator.classList.add('is-dragging');
      if (indicator.setPointerCapture) {
        try { indicator.setPointerCapture(e.pointerId); } catch (err) {}
      }
      seekFromEvent(e);
    });

    window.addEventListener('pointermove', (e) => {
      if (!isDragging) return;
      seekFromEvent(e);
    });

    const stopDragging = (e) => {
      if (isDragging) {
        isDragging = false;
        indicator.classList.remove('is-dragging');
        if (e && e.pointerId && indicator.releasePointerCapture) {
          try { indicator.releasePointerCapture(e.pointerId); } catch (err) {}
        }
      }
    };

    window.addEventListener('pointerup', stopDragging);
    window.addEventListener('pointercancel', stopDragging);
  }

  /* =========================================================================
     Mobile 3-Screen Spotlight Showcase Stage
     ========================================================================= */
  function initMobileShowcaseStage() {
    const stage = document.getElementById('real-screens-showcase');
    if (!stage) return;

    const cards = Array.from(stage.querySelectorAll('.real-screen-card'));
    if (cards.length !== 3) return;

    const prevBtn = document.getElementById('showcase-prev-btn');
    const nextBtn = document.getElementById('showcase-next-btn');

    let currentIndex = 1;

    function applySlots(activeIdx) {
      currentIndex = activeIdx;

      cards.forEach((card, idx) => {
        card.classList.remove('slot-left', 'slot-center', 'slot-right');
        if (idx === activeIdx) {
          card.classList.add('slot-center');
          card.setAttribute('aria-selected', 'true');
        } else if ((activeIdx === 0 && idx === 1) || (activeIdx === 1 && idx === 2) || (activeIdx === 2 && idx === 0)) {
          card.classList.add('slot-right');
          card.setAttribute('aria-selected', 'false');
        } else {
          card.classList.add('slot-left');
          card.setAttribute('aria-selected', 'false');
        }
      });
    }

    // Direct card click interaction
    cards.forEach((card, idx) => {
      card.addEventListener('click', () => {
        if (window.innerWidth <= 768) {
          applySlots(idx);
        }
      });

      card.addEventListener('keydown', (e) => {
        if ((e.key === 'Enter' || e.key === ' ') && window.innerWidth <= 768) {
          e.preventDefault();
          applySlots(idx);
        }
      });
    });

    // Block-shaped arrow buttons interaction
    if (prevBtn) {
      prevBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        applySlots((currentIndex + 2) % 3);
      });
    }

    if (nextBtn) {
      nextBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        applySlots((currentIndex + 1) % 3);
      });
    }

    // Touch swipe support for stage
    let touchStartX = 0;
    let touchStartY = 0;

    stage.addEventListener('touchstart', (e) => {
      if (e.touches && e.touches[0]) {
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
      }
    }, { passive: true });

    stage.addEventListener('touchend', (e) => {
      if (!e.changedTouches || !e.changedTouches[0]) return;
      const diffX = e.changedTouches[0].clientX - touchStartX;
      const diffY = e.changedTouches[0].clientY - touchStartY;

      if (Math.abs(diffX) > 35 && Math.abs(diffX) > Math.abs(diffY)) {
        if (diffX < 0) {
          applySlots((currentIndex + 1) % 3);
        } else {
          applySlots((currentIndex + 2) % 3);
        }
      }
    }, { passive: true });

    // Initialize with middle one zoomed in (index 1)
    applySlots(1);
  }

})();

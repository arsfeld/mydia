import Hls from 'hls.js'

/**
 * VideoPlayer Phoenix Hook
 *
 * Responsibilities:
 * - Initialize video player and fetch progress from server
 * - Setup HLS.js for adaptive streaming
 * - Save playback progress to server
 * - Handle keyboard shortcuts and touch gestures
 * - Coordinate with Alpine.js component for UI state
 *
 * Alpine.js handles all reactive UI state and DOM updates.
 */

const VideoPlayer = {
  mounted() {
    console.log('VideoPlayer hook mounted')

    // Wait for Alpine to initialize on this element
    if (!window.Alpine) {
      console.error('Alpine.js not loaded')
      return
    }

    // Use Alpine's official API to get the component data
    // We need to wait for Alpine to process the element
    const waitForAlpine = () => {
      try {
        // Alpine.$data is the official way to get component data from an element
        this.alpine = window.Alpine.$data(this.el)

        if (!this.alpine) {
          // Alpine hasn't initialized yet, try again
          console.log('Waiting for Alpine to initialize...')
          setTimeout(waitForAlpine, 10)
          return
        }

        console.log('Alpine component found, initializing video player')
        // Continue with initialization
        this.initializeVideoPlayer()
      } catch (error) {
        console.error('Error accessing Alpine component:', error)
      }
    }

    // Start checking for Alpine
    setTimeout(waitForAlpine, 0)
  },

  initializeVideoPlayer() {
    console.log('Initializing video player with Alpine component')

    // Get video element
    this.video = this.el.querySelector('video')

    // Get data attributes
    this.contentType = this.el.dataset.contentType
    this.contentId = this.el.dataset.contentId
    this.nextEpisode = this.el.dataset.nextEpisode ? JSON.parse(this.el.dataset.nextEpisode) : null
    this.introStart = this.el.dataset.introStart ? parseFloat(this.el.dataset.introStart) : null
    this.introEnd = this.el.dataset.introEnd ? parseFloat(this.el.dataset.introEnd) : null
    this.creditsStart = this.el.dataset.creditsStart ? parseFloat(this.el.dataset.creditsStart) : null

    if (!this.video || !this.contentType || !this.contentId) {
      console.error('VideoPlayer: Missing required elements or data attributes')
      return
    }

    // State for progress tracking
    this.hls = null
    this.progressInterval = null
    this.lastSavedPosition = 0
    this.savedPosition = 0
    this.isSeeking = false
    this.hasShownNextEpisode = false

    // HLS session management
    this.hlsSessionId = null
    this.heartbeatInterval = null

    // Autoplay countdown state
    this.autoplayCountdownInterval = null
    this.autoplayCountdownStartTime = null
    this.autoplayCountdownSeconds = 15

    // Track if video was initially muted for autoplay
    this.wasAutoMuted = this.video.muted

    // Control auto-hide state
    this.hideControlsTimeout = null

    // Click handling for play/pause and fullscreen
    this.clickTimeout = null
    this.clickCount = 0

    // Touch gesture state
    this.setupTouchState()

    // Setup keyboard shortcuts
    this.setupKeyboardShortcuts()

    // Setup touch gestures
    this.setupTouchGestures()

    // Setup controls auto-hide
    this.setupAutoHide()

    // Setup click interactions
    this.setupClickInteractions()

    // Listen to Alpine events
    this.setupAlpineEventListeners()

    // Setup fullscreen change listener
    document.addEventListener('fullscreenchange', this.handleFullscreenChange.bind(this))

    // Setup beforeunload handler to save progress on page unload
    // Note: HLS session cleanup relies on the destroyed() callback and the 2-minute timeout
    // We can't reliably terminate the session here due to browser restrictions on async operations
    this.handleBeforeUnload = () => {
      // Save progress immediately
      if (this.video && this.video.duration) {
        const data = JSON.stringify({
          position_seconds: Math.floor(this.video.currentTime),
          duration_seconds: Math.floor(this.video.duration)
        })
        navigator.sendBeacon(`/api/v1/playback/${this.contentType}/${this.contentId}`, data)
      }
    }
    window.addEventListener('beforeunload', this.handleBeforeUnload)

    // Initialize volume from localStorage
    this.initializeVolume()

    // Initialize player
    this.initializePlayer()
  },

  async initializePlayer() {
    try {
      this.alpine.showLoading()

      // Fetch playback progress
      const progress = await this.fetchProgress()
      console.log('Fetched progress:', progress)

      // Set video source
      const streamUrl = `/api/v1/stream/${this.contentType}/${this.contentId}`
      console.log('Stream URL:', streamUrl)

      // Setup video event listeners
      this.setupVideoEventListeners()

      // Store saved position before we start loading
      this.savedPosition = progress.position_seconds || 0

      // Check if the stream URL redirects to HLS
      // Make a HEAD request to detect HLS - allow redirect to follow
      const response = await fetch(streamUrl, {
        method: 'HEAD',
        credentials: 'same-origin'  // Include cookies for authentication
      })

      // Check the final URL after any redirects
      const finalUrl = response.url
      console.log('Final stream URL:', finalUrl)

      if (finalUrl && finalUrl.includes('.m3u8')) {
        // This is an HLS stream, use HLS.js
        console.log('Detected HLS stream, using HLS.js')

        // Wait for playlist to be ready (handles race condition with FFmpeg)
        await this.waitForPlaylist(finalUrl)

        this.setupHLS(finalUrl)
      } else if (response.ok) {
        // Direct play
        console.log('Using direct play')
        this.video.src = streamUrl
      } else {
        // Error response
        console.error('Stream endpoint returned error:', response.status)
        this.alpine.showError(`Failed to load stream (${response.status})`)
      }

    } catch (error) {
      console.error('Failed to initialize video player:', error)
      this.alpine.showError('Failed to load video. Please try again.')
    }
  },

  async fetchProgress() {
    const response = await fetch(`/api/v1/playback/${this.contentType}/${this.contentId}`, {
      headers: { 'Accept': 'application/json' }
    })

    if (!response.ok) {
      console.warn('Failed to fetch progress, starting from beginning')
      return { position_seconds: 0, duration_seconds: null, completion_percentage: 0, watched: false }
    }

    return await response.json()
  },

  async waitForPlaylist(playlistUrl, options = {}) {
    const maxRetries = options.maxRetries || 10
    const retryDelay = options.retryDelay || 500
    const maxDelay = options.maxDelay || 3000

    for (let i = 0; i < maxRetries; i++) {
      try {
        const response = await fetch(playlistUrl, { method: 'HEAD' })

        if (response.ok) {
          // Playlist ready
          if (i > 0) {
            console.log(`Playlist ready after ${i + 1} attempt(s)`)
          }
          return
        }

        // Calculate exponential backoff delay
        const delay = Math.min(retryDelay * Math.pow(1.5, i), maxDelay)
        console.log(`Playlist not ready (attempt ${i + 1}/${maxRetries}), retrying in ${delay}ms...`)

        await new Promise(resolve => setTimeout(resolve, delay))
      } catch (error) {
        console.warn(`Error checking playlist (attempt ${i + 1}/${maxRetries}):`, error)
        const delay = Math.min(retryDelay * Math.pow(1.5, i), maxDelay)
        await new Promise(resolve => setTimeout(resolve, delay))
      }
    }

    throw new Error('Playlist not ready after maximum retry attempts')
  },

  async saveProgress(position, duration) {
    try {
      const response = await fetch(`/api/v1/playback/${this.contentType}/${this.contentId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          position_seconds: Math.floor(position),
          duration_seconds: Math.floor(duration)
        })
      })

      if (response.ok) {
        this.lastSavedPosition = position
        console.log('Progress saved:', position)
      } else {
        console.error('Failed to save progress:', response.status)
      }
    } catch (error) {
      console.error('Error saving progress:', error)
    }
  },

  setupHLS(hlsUrl) {
    console.log('Setting up HLS:', hlsUrl)

    // Extract session ID from HLS URL (format: /api/v1/hls/{session_id}/index.m3u8)
    const sessionIdMatch = hlsUrl.match(/\/hls\/([^/]+)\//)
    if (sessionIdMatch) {
      this.hlsSessionId = sessionIdMatch[1]
      console.log('HLS session ID:', this.hlsSessionId)
    }

    if (Hls.isSupported()) {
      this.hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false
      })

      this.hls.loadSource(hlsUrl)
      this.hls.attachMedia(this.video)

      this.hls.on(Hls.Events.MANIFEST_PARSED, () => {
        console.log('HLS manifest parsed')
        this.alpine.hideLoading()

        // Update Alpine with HLS levels
        const levels = this.hls.levels.map(level => ({
          height: level.height,
          bitrate: level.bitrate
        }))
        this.alpine.updateHlsLevels(levels)
      })

      this.hls.on(Hls.Events.LEVEL_SWITCHED, () => {
        this.alpine.updateHlsLevel(this.hls.currentLevel)
      })

      this.hls.on(Hls.Events.ERROR, (event, data) => {
        console.error('HLS error:', data)

        if (data.fatal) {
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              console.error('Fatal network error, trying to recover')
              this.hls.startLoad()
              break
            case Hls.ErrorTypes.MEDIA_ERROR:
              console.error('Fatal media error, trying to recover')
              this.hls.recoverMediaError()
              break
            default:
              this.alpine.showError('Fatal error playing video')
              this.destroyHLS()
              break
          }
        }
      })
    } else if (this.video.canPlayType('application/vnd.apple.mpegurl')) {
      // Safari native HLS support
      console.log('Using Safari native HLS')
      this.video.src = hlsUrl
    } else {
      this.alpine.showError('HLS playback not supported in this browser')
    }
  },

  setupVideoEventListeners() {
    // Track whether we've set the initial position
    this.hasSetInitialPosition = false

    this.video.addEventListener('loadedmetadata', () => {
      console.log('Video metadata loaded, duration:', this.video.duration)
    })

    this.video.addEventListener('canplay', () => {
      console.log('Video can play, ready to seek')

      // Only set initial position once
      if (!this.hasSetInitialPosition && this.video.duration) {
        this.hasSetInitialPosition = true

        // Seek to saved position or start at beginning
        if (this.savedPosition > 0 && this.savedPosition < this.video.duration) {
          console.log('Seeking to saved position:', this.savedPosition)
          this.video.currentTime = this.savedPosition
        } else {
          console.log('Starting from beginning')
          this.video.currentTime = 0
        }
      }
    })

    this.video.addEventListener('durationchange', () => {
      console.log('Video duration changed to:', this.video.duration)
    })

    this.video.addEventListener('timeupdate', () => {
      this.checkTVShowFeatures()
    })

    this.video.addEventListener('play', () => {
      console.log('Video playing')
      this.startProgressTracking()
    })

    this.video.addEventListener('pause', () => {
      console.log('Video paused')
      this.stopProgressTracking()

      // Save progress immediately when paused
      if (this.video.duration) {
        this.saveProgress(this.video.currentTime, this.video.duration)
      }
    })

    this.video.addEventListener('ended', () => {
      console.log('Video ended')
      this.stopProgressTracking()

      // Save final progress
      if (this.video.duration) {
        this.saveProgress(this.video.duration, this.video.duration)
      }
    })

    this.video.addEventListener('error', (e) => {
      console.error('Video error:', e, this.video.error)
      this.stopProgressTracking()

      let errorMessage = 'Failed to load video'
      if (this.video.error) {
        switch (this.video.error.code) {
          case MediaError.MEDIA_ERR_ABORTED:
            errorMessage = 'Video playback aborted'
            break
          case MediaError.MEDIA_ERR_NETWORK:
            errorMessage = 'Network error loading video'
            break
          case MediaError.MEDIA_ERR_DECODE:
            errorMessage = 'Video decoding error'
            break
          case MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED:
            errorMessage = 'Video format not supported'
            break
        }
      }

      this.alpine.showError(errorMessage)
    })
  },

  startProgressTracking() {
    this.stopProgressTracking()

    // Save progress every 10 seconds while playing
    this.progressInterval = setInterval(() => {
      if (this.video.duration && !this.video.paused) {
        const position = this.video.currentTime
        const duration = this.video.duration

        // Only save if position has changed significantly
        if (Math.abs(position - this.lastSavedPosition) >= 1) {
          this.saveProgress(position, duration)
        }
      }
    }, 10000)

    // Start HLS heartbeat if using HLS
    this.startHlsHeartbeat()
  },

  stopProgressTracking() {
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
      this.progressInterval = null
    }

    // Stop HLS heartbeat
    this.stopHlsHeartbeat()
  },

  startHlsHeartbeat() {
    if (!this.hlsSessionId) return

    this.stopHlsHeartbeat()

    // Send heartbeat every 30 seconds to keep session alive
    this.heartbeatInterval = setInterval(() => {
      if (!this.video.paused && this.hlsSessionId) {
        console.log('Sending HLS heartbeat for session:', this.hlsSessionId)
        // Heartbeat is automatically sent when fetching playlists/segments
        // We don't need explicit heartbeat calls since HLS.js regularly fetches segments
      }
    }, 30000)
  },

  stopHlsHeartbeat() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
      this.heartbeatInterval = null
    }
  },

  async terminateHlsSession() {
    if (!this.hlsSessionId) return

    try {
      console.log('Terminating HLS session:', this.hlsSessionId)
      const response = await fetch(`/api/v1/hls/${this.hlsSessionId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        console.log('HLS session terminated successfully')
      } else {
        console.warn('Failed to terminate HLS session:', response.status)
      }
    } catch (error) {
      console.error('Error terminating HLS session:', error)
    }

    this.hlsSessionId = null
  },

  checkTVShowFeatures() {
    if (!this.video.duration || this.contentType !== 'episode') return

    const currentTime = this.video.currentTime
    const duration = this.video.duration
    const progress = (currentTime / duration) * 100

    // Check skip intro
    if (this.introStart !== null && this.introEnd !== null) {
      if (currentTime >= this.introStart && currentTime < this.introEnd) {
        this.alpine.showSkipIntro()
      } else {
        this.alpine.hideSkipIntro()
      }
    }

    // Check skip credits
    if (this.creditsStart !== null) {
      if (currentTime >= this.creditsStart) {
        this.alpine.showSkipCredits()
      } else {
        this.alpine.hideSkipCredits()
      }
    }

    // Check next episode display
    if (this.nextEpisode && !this.hasShownNextEpisode) {
      const shouldShow = progress > 90 || (this.creditsStart !== null && currentTime >= this.creditsStart)

      if (shouldShow) {
        this.alpine.showNextEpisode()
        this.hasShownNextEpisode = true
      }
    }
  },

  setupAlpineEventListeners() {
    // Listen to events from Alpine component
    this.el.addEventListener('skip-intro', () => {
      if (this.introEnd !== null) {
        this.video.currentTime = this.introEnd
        this.alpine.hideSkipIntro()
      }
    })

    this.el.addEventListener('skip-credits', () => {
      if (this.nextEpisode) {
        this.navigateToNextEpisode()
      } else {
        this.video.currentTime = this.video.duration
      }
      this.alpine.hideSkipCredits()
    })

    this.el.addEventListener('play-next-episode', () => {
      this.stopAutoplayCountdown()
      this.navigateToNextEpisode()
    })

    this.el.addEventListener('cancel-next-episode', () => {
      this.stopAutoplayCountdown()
    })

    this.el.addEventListener('set-quality', (e) => {
      if (this.hls) {
        this.hls.currentLevel = e.detail.level
      }
    })

    // Start autoplay countdown when video ends
    this.video.addEventListener('ended', () => {
      if (this.nextEpisode) {
        this.startAutoplayCountdown()
      }
    }, { once: false })
  },

  navigateToNextEpisode() {
    if (!this.nextEpisode) return

    // Save current progress before navigating
    if (this.video.duration) {
      this.saveProgress(this.video.currentTime, this.video.duration)
    }

    window.location.href = `/playback/episode/${this.nextEpisode.id}`
  },

  startAutoplayCountdown() {
    if (!this.nextEpisode) return

    this.alpine.startCountdown()
    this.autoplayCountdownStartTime = Date.now()
    const totalDuration = this.autoplayCountdownSeconds * 1000

    this.autoplayCountdownInterval = setInterval(() => {
      const elapsed = Date.now() - this.autoplayCountdownStartTime
      const remaining = Math.max(0, totalDuration - elapsed)
      const secondsRemaining = Math.ceil(remaining / 1000)
      const progressPercent = ((totalDuration - remaining) / totalDuration) * 100

      this.alpine.updateCountdown(secondsRemaining, progressPercent)

      if (remaining === 0) {
        this.stopAutoplayCountdown()
        this.navigateToNextEpisode()
      }
    }, 100)
  },

  stopAutoplayCountdown() {
    if (this.autoplayCountdownInterval) {
      clearInterval(this.autoplayCountdownInterval)
      this.autoplayCountdownInterval = null
    }
    this.alpine.stopCountdown()
  },

  initializeVolume() {
    const savedVolume = localStorage.getItem('videoPlayerVolume')
    if (savedVolume !== null) {
      const volume = parseInt(savedVolume)
      this.video.volume = volume / 100
      this.alpine.volume = volume
    }

    const savedSpeed = localStorage.getItem('videoPlayerSpeed')
    if (savedSpeed !== null) {
      this.video.playbackRate = parseFloat(savedSpeed)
      this.alpine.playbackRate = parseFloat(savedSpeed)
    }
  },

  setupAutoHide() {
    this.el.addEventListener('mousemove', () => {
      this.alpine.controlsVisible = true
      this.resetHideControlsTimeout()
    })

    this.video.addEventListener('pause', () => {
      this.alpine.controlsVisible = true
      this.clearHideControlsTimeout()
    })

    this.video.addEventListener('play', () => {
      this.resetHideControlsTimeout()
    })
  },

  resetHideControlsTimeout() {
    this.clearHideControlsTimeout()

    if (!this.video.paused) {
      this.hideControlsTimeout = setTimeout(() => {
        this.alpine.controlsVisible = false
      }, 3000)
    }
  },

  clearHideControlsTimeout() {
    if (this.hideControlsTimeout) {
      clearTimeout(this.hideControlsTimeout)
      this.hideControlsTimeout = null
    }
  },

  setupClickInteractions() {
    this.video.addEventListener('click', () => {
      this.clickCount++

      if (this.clickCount === 1) {
        this.clickTimeout = setTimeout(() => {
          // Single click - toggle play/pause (will also unmute if needed)
          this.alpine.togglePlay()
          this.clickCount = 0
        }, 300)
      } else if (this.clickCount === 2) {
        // Double click - toggle fullscreen
        clearTimeout(this.clickTimeout)
        this.clickCount = 0
        this.alpine.toggleFullscreen()
      }
    })
  },

  setupKeyboardShortcuts() {
    this.el.addEventListener('keydown', (e) => {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return

      let handled = true

      switch(e.key.toLowerCase()) {
        case ' ':
        case 'k':
          e.preventDefault()
          this.alpine.togglePlay()
          break

        case 'f':
          e.preventDefault()
          this.alpine.toggleFullscreen()
          break

        case 'm':
          e.preventDefault()
          this.alpine.toggleMute()
          break

        case 'arrowup':
          e.preventDefault()
          this.changeVolume(0.05)
          break

        case 'arrowdown':
          e.preventDefault()
          this.changeVolume(-0.05)
          break

        case 'arrowleft':
          e.preventDefault()
          this.seek(-5)
          break

        case 'arrowright':
          e.preventDefault()
          this.seek(5)
          break

        case 'j':
          e.preventDefault()
          this.seek(-10)
          break

        case 'l':
          e.preventDefault()
          this.seek(10)
          break

        case 'home':
          e.preventDefault()
          this.video.currentTime = 0
          break

        case 'end':
          e.preventDefault()
          this.video.currentTime = this.video.duration
          break

        case '<':
        case ',':
          e.preventDefault()
          this.changePlaybackSpeed(-0.25)
          break

        case '>':
        case '.':
          e.preventDefault()
          this.changePlaybackSpeed(0.25)
          break

        default:
          if (e.key >= '0' && e.key <= '9') {
            e.preventDefault()
            const percentage = parseInt(e.key) * 10
            this.video.currentTime = (this.video.duration * percentage) / 100
          } else {
            handled = false
          }
      }

      if (handled) {
        this.alpine.controlsVisible = true
        this.resetHideControlsTimeout()
      }
    })

    // Make player focusable
    this.el.setAttribute('tabindex', '0')
    this.el.addEventListener('click', () => this.el.focus())
  },

  changeVolume(delta) {
    const newVolume = Math.max(0, Math.min(1, this.video.volume + delta))
    this.alpine.setVolume(newVolume * 100)
  },

  seek(seconds) {
    if (!this.video.duration) return
    this.video.currentTime = Math.max(0, Math.min(this.video.duration, this.video.currentTime + seconds))
  },

  changePlaybackSpeed(delta) {
    const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    const currentSpeed = this.video.playbackRate
    let newIndex = speeds.findIndex(s => Math.abs(s - currentSpeed) < 0.01)

    if (newIndex === -1) {
      newIndex = speeds.findIndex(s => s >= currentSpeed)
      if (newIndex === -1) newIndex = speeds.length - 1
    }

    newIndex += (delta > 0 ? 1 : -1)
    newIndex = Math.max(0, Math.min(speeds.length - 1, newIndex))

    this.alpine.setSpeed(speeds[newIndex])
  },

  handleFullscreenChange() {
    // Trigger Alpine reactivity
    this.alpine.$nextTick()
  },

  setupTouchState() {
    this.touchStartX = 0
    this.touchStartY = 0
    this.touchStartTime = 0
    this.lastTapTime = 0
    this.lastTapX = 0
    this.volumeAdjustStart = 0
    this.isTouchDragging = false
  },

  setupTouchGestures() {
    if (!('ontouchstart' in window)) return

    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)

    this.video.addEventListener('touchstart', (e) => {
      const touch = e.touches[0]
      this.touchStartX = touch.clientX
      this.touchStartY = touch.clientY
      this.touchStartTime = Date.now()
      this.isTouchDragging = false

      if (this.touchStartX > this.video.offsetWidth / 2) {
        this.volumeAdjustStart = this.video.volume
      }

      e.preventDefault()
    }, { passive: false })

    this.video.addEventListener('touchmove', (e) => {
      if (e.touches.length !== 1) return

      const touch = e.touches[0]
      const deltaX = touch.clientX - this.touchStartX
      const deltaY = touch.clientY - this.touchStartY

      if (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10) {
        this.isTouchDragging = true
      }

      // Right side vertical swipe for volume
      if (this.touchStartX > this.video.offsetWidth / 2 && Math.abs(deltaY) > 20 && Math.abs(deltaX) < 50) {
        const volumeChange = -deltaY / 200
        const newVolume = Math.max(0, Math.min(1, this.volumeAdjustStart + volumeChange))
        this.alpine.setVolume(newVolume * 100)
        e.preventDefault()
      }
    }, { passive: false })

    this.video.addEventListener('touchend', () => {
      const touchEndTime = Date.now()
      const touchDuration = touchEndTime - this.touchStartTime

      if (this.isTouchDragging) {
        if (this.touchStartX > this.video.offsetWidth / 2) {
          localStorage.setItem('videoPlayerVolume', Math.round(this.video.volume * 100).toString())
        }
        return
      }

      // Tap gesture
      if (touchDuration < 300) {
        const tapX = this.touchStartX
        const videoWidth = this.video.offsetWidth

        const timeSinceLastTap = touchEndTime - this.lastTapTime
        const isDoubleTap = timeSinceLastTap < 300 && Math.abs(tapX - this.lastTapX) < 50

        if (isDoubleTap) {
          if (tapX < videoWidth / 3) {
            this.seek(-10)
          } else if (tapX > (videoWidth * 2) / 3) {
            this.seek(10)
          } else {
            this.alpine.toggleFullscreen()
          }
          this.lastTapTime = 0
        } else {
          this.alpine.controlsVisible = !this.alpine.controlsVisible
          if (this.alpine.controlsVisible) {
            this.resetHideControlsTimeout()
          }
          this.lastTapTime = touchEndTime
          this.lastTapX = tapX
        }
      }
    })

    // Wake lock for mobile
    if ('wakeLock' in navigator && isMobile) {
      let wakeLock = null

      const requestWakeLock = async () => {
        try {
          wakeLock = await navigator.wakeLock.request('screen')
          console.log('Wake lock acquired')
        } catch (err) {
          console.error('Wake lock error:', err)
        }
      }

      const releaseWakeLock = async () => {
        if (wakeLock) {
          await wakeLock.release()
          wakeLock = null
        }
      }

      this.video.addEventListener('play', requestWakeLock)
      this.video.addEventListener('pause', releaseWakeLock)
      this.video.addEventListener('ended', releaseWakeLock)

      this.releaseWakeLock = releaseWakeLock
    }
  },

  destroyHLS() {
    if (this.hls) {
      this.hls.destroy()
      this.hls = null
    }
  },

  async destroyed() {
    console.log('VideoPlayer hook destroyed')

    // Remove beforeunload handler
    if (this.handleBeforeUnload) {
      window.removeEventListener('beforeunload', this.handleBeforeUnload)
    }

    // Save final progress
    if (this.video && this.video.duration) {
      this.saveProgress(this.video.currentTime, this.video.duration)
    }

    // Terminate HLS session if active
    await this.terminateHlsSession()

    // Clean up
    this.clearHideControlsTimeout()
    if (this.clickTimeout) clearTimeout(this.clickTimeout)
    this.stopAutoplayCountdown()
    this.stopProgressTracking()
    this.destroyHLS()
    if (this.releaseWakeLock) this.releaseWakeLock()
  }
}

export default VideoPlayer

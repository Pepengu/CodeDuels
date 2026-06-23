// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/code_duels"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.MathJaxHook = {
  mounted() {
    this.renderMath()
    this.addCopyButtons()
    this.syncTestLines()
  },
  updated() {
    this.renderMath()
    this.addCopyButtons()
    this.syncTestLines()
  },
  renderMath() {
    if (window.MathJax && window.MathJax.Hub) {
      window.MathJax.Hub.Queue(["Typeset", window.MathJax.Hub, this.el]);
    } else {
      setTimeout(() => this.renderMath(), 100);
    }
  },
  addCopyButtons() {
    this.el.querySelectorAll(".input, .output").forEach(el => {
      if (el.querySelector(".copy-sample-btn")) return

      const title = el.querySelector(".title")
      if (!title) return

      const btn = document.createElement("button")
      btn.className = "copy-sample-btn"
      btn.setAttribute("aria-label", "Копировать")

      const icon = document.createElement("span")
      icon.className = "hero-clipboard-document-mini"

      btn.appendChild(icon)
      btn.addEventListener("click", () => {
        const pre = el.querySelector("pre.content")
        if (pre) {
          navigator.clipboard.writeText(pre.textContent.trim())
          icon.className = "hero-clipboard-document-check-mini"
          setTimeout(() => icon.className = "hero-clipboard-document-mini", 2000)
        }
      })
      title.appendChild(btn)
    })
  },
  syncTestLines() {
    this.el.querySelectorAll(".sample-test").forEach(sample => {
      const inputs = sample.querySelectorAll(".input pre.content")
      const outputs = sample.querySelectorAll(".output pre.content")
      if (inputs.length === 0 || outputs.length === 0) return

      const pairs = Math.min(inputs.length, outputs.length)
      for (let i = 0; i < pairs; i++) {
        const input = inputs[i]
        const output = outputs[i]

        const sync = (from, to) => {
          from.querySelectorAll("[class*='test-example-line']").forEach(line => {
            line.addEventListener("mouseenter", () => {
              const cls = [...line.classList].find(c => /test-example-line-\d+/.test(c))
              if (!cls) return
              const toMatch = to.querySelectorAll(`.${CSS.escape(cls)}`)
              if (toMatch.length === 0) return
              from.querySelectorAll(`.${CSS.escape(cls)}`).forEach(l => l.classList.add("test-line-hover"))
              toMatch.forEach(l => l.classList.add("test-line-hover"))
            })
            line.addEventListener("mouseleave", () => {
              const cls = [...line.classList].find(c => /test-example-line-\d+/.test(c))
              if (!cls) return
              from.querySelectorAll(`.${CSS.escape(cls)}`).forEach(l => l.classList.remove("test-line-hover"))
              to.querySelectorAll(`.${CSS.escape(cls)}`).forEach(l => l.classList.remove("test-line-hover"))
            })
          })
        }

        sync(input, output)
        sync(output, input)
      }
    })
  }
}

Hooks.LanguageSelectHook = {
  mounted() {
    const saved = localStorage.getItem("last_language")
    if (saved && saved !== this.el.value) {
      this.pushEvent("restore_language", {language: saved})
    }
    this.el.addEventListener("change", () => {
      localStorage.setItem("last_language", this.el.value)
    })
  }
}

function formatTime(seconds) {
  if (seconds < 60) return seconds + " сек"
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return m + " мин " + s + " сек"
}

Hooks.CountdownHook = {
  mounted() {
    this.update()
    this.interval = setInterval(() => this.update(), 1000)
  },
  updated() {
    this.update()
  },
  destroyed() {
    clearInterval(this.interval)
  },
  update() {
    const now = Math.floor(Date.now() / 1000)
    const unlock = parseInt(this.el.dataset.unlock)
    const end = parseInt(this.el.dataset.end)

    if (isNaN(unlock) || isNaN(end)) {
      this.el.textContent = ""
      return
    }

    if (now < unlock) {
      this.el.textContent = "До начала " + formatTime(unlock - now)
      return
    }

    if (now < end) {
      this.el.textContent = formatTime(end - now)
      return
    }

    this.el.textContent = "Завершён"
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...Hooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

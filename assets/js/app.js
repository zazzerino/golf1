import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {loadTextures, GameContext} from "./game_context"

loadTextures();

let hooks = {};
let gameContext;

// The div this connects to is in GolfWeb.GameLive.
hooks.GameCanvas = {
  mounted() {
    this.handleEvent("game-loaded", data => {
      console.log("game loaded", data);
      gameContext = new GameContext(data.game, this.el, this.pushEvent.bind(this));
    });

    this.handleEvent("round-started", data => {
      console.log("round started", data);
      gameContext.onRoundStart(data.game);
    });

    this.handleEvent("game-event", data => {
      console.log("game event", data);
      gameContext.onGameEvent(data.game, data.event);
    });
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
const params = {_csrf_token: csrfToken};
const liveSocket = new LiveSocket("/live", Socket, {params, hooks});

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
// window.liveSocket = liveSocket

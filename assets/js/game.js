import * as PIXI from "pixi.js";
import {OutlineFilter} from "@pixi/filter-outline";

const GAME_WIDTH = 600;
const GAME_HEIGHT = 600;

const CENTER_X = GAME_WIDTH / 2;
const CENTER_Y = GAME_HEIGHT / 2;

const CARD_IMG_WIDTH = 88;
const CARD_IMG_HEIGHT = 124;

const CARD_SCALE = 0.75;

const CARD_WIDTH = CARD_IMG_WIDTH * CARD_SCALE;
const CARD_HEIGHT = CARD_IMG_HEIGHT * CARD_SCALE;

const DECK_X_INIT = CENTER_X;

const DECK_X = CENTER_X - CARD_WIDTH / 2;
const DECK_Y = CENTER_Y;

/**
The deck png has 5 pixels of cards below the top card.
This offset lets us place cards correctly on top of the deck.
*/
const DECK_Y_OFFSET = -5;

const TABLE_CARD_X = CENTER_X + CARD_WIDTH / 2 + 2;
const TABLE_CARD_Y = CENTER_Y;

const HAND_X_PADDING = 3;
const HAND_Y_PADDING = 10;

const HAND_SIZE = 6;

const DECK_CARD = "1B";
const DOWN_CARD = "2B";

const SPRITESHEET = "/images/spritesheets/cards.json";
const HOVER_CURSOR_STYLE = "url('/images/cursor-click.png'),auto";

const CANVAS_COLOR = "forestgreen";

export function loadTextures() {
  PIXI.Assets.backgroundLoad(SPRITESHEET);
}

export class GameContext {
  constructor(game, parentEl, pushEvent) {
    this.game = game;
    this.parentEl = parentEl;
    this.pushEvent = pushEvent;
    
    this.sprites = {
      table: [],
      hands: {bottom: [], left: [], top: [], right: []},
    };

    this.renderer = new PIXI.Renderer({
      width: GAME_WIDTH,
      height: GAME_HEIGHT,
      backgroundColor: CANVAS_COLOR,
      antialias: true,
    });

    this.stage = new PIXI.Container();
    this.renderer.render(this.stage);
    this.renderer.events.cursorStyles.hover = HOVER_CURSOR_STYLE;

    PIXI.Assets.load([SPRITESHEET])
      .then(assets => {
        this.textures = assets[SPRITESHEET].textures;
        this.parentEl.appendChild(this.renderer.view);
        this.addSprites();
        this.renderer.render(this.stage);
        requestAnimationFrame(time => this.drawLoop(time));
      });
  }

  drawLoop(_time) {
    requestAnimationFrame(time => this.drawLoop(time));
    this.renderer.render(this.stage);
  }

  // server events

  onRoundStart(game) {
    this.game = game;
    this.sprites.deck.x = DECK_X;
    this.addTableCards();

    for (const player of this.game.players) {
      this.addHand(player);
    }
  }

  onGameEvent(game, event) {
    this.game = game;

    switch (event.action) {
      case "flip":
        this.onFlip(event);
        break;
    }
  }

  onFlip(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    const cardName = player.hand[event.hand_index]["name"];
    const handSprites = this.sprites.hands[player.position];
    const sprite = handSprites[event.hand_index];
    sprite.texture = this.textures[cardName];

    for (let i = 0; i < HAND_SIZE; i++) {
      const place = `hand_${i}`;
      if (!this.isPlayable(place)) {
        makeUnplayable(handSprites[i]);
      }
    }

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, this.onDeckClick.bind(this));
    }

    if (this.isPlayable("table")) {
      makePlayable(this.sprites.table[0], this.onTableClick.bind(this));
    }
  }

  // sprites

  addSprites() {
    this.addDeck();
    
    if (this.game.state) {
      this.addTableCards();
      
      for (const player of this.game.players) {
        this.addHand(player);

        if (player.held_card) {
          this.addHeldCard(player);
        }
      }
    }
  }

  addDeck() {
    const x = deckX(this.game.state);
    const texture = this.textures[DECK_CARD];
    const sprite = makeCardSprite(texture, x, DECK_Y);
    this.sprites.deck = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable("deck")) {
      makePlayable(sprite, this.onDeckClick.bind(this));
    }
  }

  addTableCards() {
    const card0 = this.game.tableCards[0];
    const card1 = this.game.tableCards[1];

    if (card1) {
      this.addTableCards(card1);
    }

    if (card0) {
      const sprite = this.addTableCard(card0);

      if (this.isPlayable("table")) {
        makePlayable(sprite, this.onTableClick.bind(this));
      }
    }
  }

  addTableCard(card) {
    const texture = this.textures[card];
    const sprite = makeCardSprite(texture, TABLE_CARD_X, TABLE_CARD_Y);
    this.sprites.table.unshift(sprite);
    this.stage.addChild(sprite);
    return sprite;
  }

  addHand(player) {
    for (let i = 0; i < HAND_SIZE; i++) {
      const card = player.hand[i];
      const name = card["face_up?"] ? card.name : DOWN_CARD;
      const texture = this.textures[name];
      const coord = handCardCoord(player.position, i);
      const sprite = makeCardSprite(texture, coord.x, coord.y);
      const place = `hand_${i}`;

      if (player.id == this.game.playerId && this.isPlayable(place)) {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      }

      this.sprites.hands[player.position][i] = sprite;
      this.stage.addChild(sprite);
    }
  }

  addHeldCard(player) {
    const texture = this.textures[player.held_card];
    const coord = heldCardCoord(player.position);
    const sprite = makeCardSprite(texture, coord.x, coord.y, coord.rotation);
    this.sprites.held = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable("held")) {
      makePlayable(sprite, this.onHeldClick.bind(this));
    }
  }

  // client events

  onDeckClick() {
    this.pushEvent("deck-click", {playerId: this.game.playerId})
  }

  onTableClick() {
    console.log("table clicked");
  }

  onHandClick(playerId, handIndex) {
    this.pushEvent("hand-click", {playerId, handIndex});
  }

  onHeldClick() {
    console.log("held clicked");
  }

  isPlayable(place) {
    return this.game.playableCards.includes(place);
  }
}

// sprite helpers

function makeCardSprite(texture, x = 0, y = 0, rotation = 0) {
  const sprite = PIXI.Sprite.from(texture);
  sprite.scale.set(CARD_SCALE, CARD_SCALE);
  sprite.anchor.set(0.5);
  sprite.x = x;
  sprite.y = y;
  sprite.rotation = rotation;
  return sprite;
}

const PLAYABLE_FILTER = new OutlineFilter(2, 0xff00ff, 1.0);

function makePlayable(sprite, callback) {
  sprite.eventMode = "static";
  sprite.cursor = "hover"
  sprite.filters = [PLAYABLE_FILTER];
  sprite.removeAllListeners();
  sprite.on("pointerdown", event => callback(event.currentTarget));
}

function makeUnplayable(sprite) {
  sprite.eventMode = "none";
  sprite.cursor = "default";
  sprite.filters = [];
  sprite.removeAllListeners();
}

// sprite coords

function deckX(state) {
  return state ? DECK_X : DECK_X_INIT;
}

function playerRotation(position) {
  return position == "left" || position === "right"
    ? toRadians(90)
    : 0;
}

function heldCardCoord(
  position, yPadding = HAND_Y_PADDING
) {
  let x, y;

  switch (position) {
    case "bottom":
      x = CENTER_X + CARD_WIDTH * 2.5;
      y = GAME_HEIGHT - CARD_HEIGHT - yPadding;
      break;

    case "left":
      x = CARD_HEIGHT + yPadding;
      y = CENTER_Y + CARD_WIDTH * 2.5;
      break;

    case "top":
      x = CENTER_X - CARD_WIDTH * 2.5;
      y = CARD_HEIGHT + yPadding;
      break;

    case "right":
      x = GAME_WIDTH - CARD_HEIGHT - yPadding;
      y = CENTER_Y - CARD_WIDTH * 2.5
      break;
  }

  const rotation = playerRotation(position);
  return { x, y, rotation }
}

function handCardCoord(
  position, index, xPadding = HAND_X_PADDING, yPadding = HAND_Y_PADDING
) {
  let x = 0, y = 0;

  if (position === "bottom") {
    switch (index) {
      case 0:
        x = CENTER_X - CARD_WIDTH - xPadding;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPadding * 1.3;
        break;

      case 1:
        x = CENTER_X;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPadding * 1.3;
        break;

      case 2:
        x = CENTER_X + CARD_WIDTH + xPadding;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPadding * 1.3;
        break;

      case 3:
        x = CENTER_X - CARD_WIDTH - xPadding;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPadding;
        break;

      case 4:
        x = CENTER_X;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPadding;
        break;

      case 5:
        x = CENTER_X + CARD_WIDTH + xPadding;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPadding;
        break;
    }
  } else if (position === "top") {
    switch (index) {
      case 0:
        x = CENTER_X + CARD_WIDTH + xPadding;
        y = CARD_HEIGHT * 1.5 + yPadding * 1.3;
        break;

      case 1:
        x = CENTER_X;
        y = CARD_HEIGHT * 1.5 + yPadding * 1.3;
        break;

      case 2:
        x = CENTER_X - CARD_WIDTH - xPadding;
        y = CARD_HEIGHT * 1.5 + yPadding * 1.3;
        break;

      case 3:
        x = CENTER_X + CARD_WIDTH + xPadding;
        y = CARD_HEIGHT / 2 + yPadding;
        break;

      case 4:
        x = CENTER_X;
        y = CARD_HEIGHT / 2 + yPadding;
        break;

      case 5:
        x = CENTER_X - CARD_WIDTH - xPadding;
        y = CARD_HEIGHT / 2 + yPadding;
        break;
    }
  } else if (position === "left") {
    switch (index) {
      case 0:
        x = CARD_HEIGHT * 1.5 + yPadding * 1.3;
        y = CENTER_Y - CARD_WIDTH - xPadding;
        break;

      case 1:
        x = CARD_HEIGHT * 1.5 + yPadding * 1.3;
        y = CENTER_Y;
        break;

      case 2:
        x = CARD_HEIGHT * 1.5 + yPadding * 1.3;
        y = CENTER_Y + CARD_WIDTH + xPadding;
        break;

      case 3:
        x = CARD_HEIGHT / 2 + yPadding;
        y = CENTER_Y - CARD_WIDTH - xPadding;
        break;

      case 4:
        x = CARD_HEIGHT / 2 + yPadding;
        y = CENTER_Y;
        break;

      case 5:
        x = CARD_HEIGHT / 2 + yPadding;
        y = CENTER_Y + CARD_WIDTH + xPadding;
        break;
    }
  } else if (position === "right") {
    switch (index) {
      case 0:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPadding * 1.3;
        y = CENTER_Y + CARD_WIDTH + xPadding;
        break;

      case 1:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPadding * 1.3;
        y = CENTER_Y;
        break;

      case 2:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPadding * 1.3;
        y = CENTER_Y - CARD_WIDTH - xPadding;
        break;

      case 3:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPadding;
        y = CENTER_Y + CARD_WIDTH + xPadding;
        break;

      case 4:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPadding;
        y = CENTER_Y;
        break;

      case 5:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPadding;
        y = CENTER_Y - CARD_WIDTH - xPadding;
        break;
    }
  }

  const rotation = playerRotation(position);
  return { x, y, rotation };
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

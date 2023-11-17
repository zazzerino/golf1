import * as PIXI from "pixi.js";
import {OutlineFilter} from "@pixi/filter-outline";
import {Tween, Easing, update as updateTweens} from "@tweenjs/tween.js";

const GAME_WIDTH = 600;
const GAME_HEIGHT = 600;

const CENTER_X = GAME_WIDTH / 2;
const CENTER_Y = GAME_HEIGHT / 2;

const CARD_IMG_WIDTH = 88;
const CARD_IMG_HEIGHT = 124;

const CARD_SCALE = 0.75;

const CARD_WIDTH = CARD_IMG_WIDTH * CARD_SCALE;
const CARD_HEIGHT = CARD_IMG_HEIGHT * CARD_SCALE;

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

  drawLoop(time) {
    requestAnimationFrame(time => this.drawLoop(time));
    updateTweens(time);
    this.renderer.render(this.stage);
  }

  isPlayable(place) {
    return this.game.playableCards.includes(place);
  }

  // server events

  onRoundStart(game) {
    this.game = game;

    for (const player of this.game.players) {
      this.addHand(player);

      this.tweenHandDeal(player.position)
        .forEach((tween, i) => {
          tween.start();

          // start tweening the deck half way through the hand animation
          if (i === HAND_SIZE / 2) {
            tween.onComplete(() => {
              this.tweenDeckDeal()
                .start()
                .onComplete(() => {
                  this.addTableCards();
                  this.tweenTableDeck().start();
                });
            });
          }
        });
    }
  }

  onGameEvent(game, event) {
    this.game = game;

    switch (event.action) {
      case "flip":
        return this.onFlip(event);
      
      case "take_from_deck":
        return this.onTakeFromDeck(event);

      case "take_from_table":
        return this.onTakeFromTable(event);

      case "discard":
        return this.onDiscard(event);

      case "swap":
        return this.onSwap(event);

      default:
        throw new Error("event does not have a valid action", event);
    }
  }

  onFlip(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on flip");

    const card = player.hand[event.hand_index]["name"];
    const handSprites = this.sprites.hands[player.position];

    const sprite = handSprites[event.hand_index];
    sprite.texture = this.textures[card];

    for (let i = 0; i < HAND_SIZE; i++) {
      if (!this.isPlayable(`hand_${i}`)) {
        makeUnplayable(handSprites[i]);
      }
    }

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, this.onDeckClick.bind(this));
    }

    // a player could flip a hand card before the table card is drawn
    // so we also need to check if it exists
    if (this.sprites.table[0] && this.isPlayable("table")) {
      makePlayable(this.sprites.table[0], this.onTableClick.bind(this));
    }
  }

  onTakeFromDeck(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take from deck");

    const heldSprite = this.addHeldCard(player);
    this.tweenHeldDeck(player.position).start();
    
    const isUsersEvent = player.id === this.game.playerId;
    if (isUsersEvent) {
      makePlayable(heldSprite, this.onHeldClick.bind(this));
      makeUnplayable(this.sprites.deck);

      const tableSprite = this.sprites.table[0];
      if (tableSprite) {
        makeUnplayable(tableSprite);
      }

      const handSprites = this.sprites.hands[player.position];
      handSprites.forEach((sprite, index) => {
        makePlayable(sprite, () => this.onHandClick(player.id, index));
      });
    }
  }

  onTakeFromTable(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take from table");

    const heldSprite = this.addHeldCard(player);
    this.tweenHeldTable().start();

    if (player.id === this.game.playerId) {
      makeUnplayable(this.sprites.deck);
      makePlayable(heldSprite, this.onHeldClick.bind(this));

      const handSprites = this.sprites.hands[player.position];
      handSprites.forEach((sprite, index) => {
        makePlayable(sprite, () => this.onHandClick(player.id, index));
      });
    }
  }

  onDiscard(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on discard");
    
    this.addTableCards();
    this.tweenTableDiscard(player.position).start();

    const handSprites = this.sprites.hands[player.position];

    handSprites.forEach((sprite, index) => {
      if (!this.isPlayable(`hand_${index}`)) {
        makeUnplayable(sprite);
      }

      // if the game is over, flip all the player's cards
      if (this.game.state === "over") {
        const cardName = player.hand[index].name;
        sprite.texture = this.textures[cardName];
      }
    });

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, this.onDeckClick.bind(this));
    }
  }

  onSwap(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on swap");

    const handSprites = this.sprites.hands[player.position]
    const handSprite = handSprites[event.hand_index];

    const cardName = player.hand[event.hand_index].name;
    handSprite.texture = this.textures[cardName];

    // this.sprites.held.visible = false;
    // this.sprites.held = null;

    const tableCard = this.game.tableCards[0];
    const firstTexture = this.textures[tableCard];

    let tableSprite = this.sprites.table[0];
    if (tableSprite) {
      tableSprite.texture = firstTexture;

      const secondCard = this.game.tableCards[1];
      if (secondCard) {
        const secondSprite = this.sprites.table[1];
        const secondTexture = this.textures[secondCard];

        if (secondSprite) {
          secondSprite.texture = this.textures[secondTexture];
        } else {
          const sprite = makeCardSprite(secondTexture, TABLE_CARD_X, TABLE_CARD_Y);
          this.sprites.table[1] = sprite;
          this.stage.addChild(sprite);

          // redraw the first table card so it's on top
          tableSprite.visible = false;
          makeUnplayable(tableSprite);
          tableSprite = makeCardSprite(firstTexture, TABLE_CARD_X, TABLE_CARD_Y);
          this.sprites.table[0] = tableSprite;
          this.stage.addChild(tableSprite);
        }
      }
    } else {
      tableSprite = makeCardSprite(firstTexture, TABLE_CARD_X, TABLE_CARD_Y);
      this.sprites.table[0] = tableSprite;
      this.stage.addChild(tableSprite);
    }

    const [heldTween, tableTween] = this.tweenSwapHeld(player.position, handSprite, tableSprite);
    heldTween.start();
    tableTween.start();

    if (this.game.isFlipped) {
      handSprites.forEach((sprite, i) => {
        const card = player.hand[i]["name"];
        sprite.texture = this.textures[card];
      });
    }

    const isUsersEvent = player.id === this.game.playerId;
    if (isUsersEvent) {
      for (const sprite of handSprites) {
        makeUnplayable(sprite);
      }
    }

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, this.onDeckClick.bind(this));
    }

    if (this.isPlayable("table")) {
      makePlayable(tableSprite, this.onTableClick.bind(this));
    }
  }
  
  // tweens

  tweenHandDeal(position) {
    const tweens = [];
    const sprites = this.sprites.hands[position];

    for (let i = sprites.length - 1; i >= 0; i--) {
      const sprite = sprites[i];
      const x = sprite.x;
      const y = sprite.y;
      const rotation = posRotation(position);

      sprite.x = CENTER_X;
      sprite.y = DECK_Y + DECK_Y_OFFSET;
      sprite.rotation = 0;

      const tween = new Tween(sprite)
        .to({x, y, rotation})
        .easing(Easing.Cubic.InOut)
        .delay((HAND_SIZE - 1 - i) * 180);

      tweens.push(tween);
    }

    return tweens;
  }

  tweenDeckDeal() {
    return new Tween(this.sprites.deck)
      .to({x: DECK_X}, 200)
      .easing(Easing.Quadratic.Out);
  }

  tweenTableDeck() {
    const table = this.sprites.table[0];
    table.x = DECK_X;

    return new Tween(table)
      .to({x: TABLE_CARD_X}, 400)
      .easing(Easing.Quadratic.Out);
  }

  tweenHeldDeck(position) {
    const held = this.sprites.held;
    const x = held.x;
    const y = held.y;
    const rotation = posRotation(position);

    held.x = this.sprites.deck.x;
    held.y = this.sprites.deck.y + DECK_Y_OFFSET;
    held.rotation = 0;

    return new Tween(held)
      .to({x, y, rotation}, 800)
      .delay(150)
      .easing(Easing.Quadratic.InOut);
  }

  tweenHeldTable(position) {
    const held = this.sprites.held;
    const x = held.x;
    const y = held.y;
    const rotation = posRotation(position);
    
    const table = this.sprites.table.shift();

    held.x = table.x;
    held.y = table.y;
    held.rotation = 0;

    return new Tween(held)
      .onStart(() => table.visible = false)
      .to({x, y, rotation}, 800)
      .easing(Easing.Quadratic.InOut);
  }

  tweenTableDiscard(position) {
    const table = this.sprites.table[0];
    const held = this.sprites.held;
    held.visible = false;

    const x = table.x;
    const y = table.y;

    table.x = held.x;
    table.y = held.y;
    table.rotation = posRotation(position);

    return new Tween(table)
      .to({x, y, rotation: 0}, 800)
      .easing(Easing.Quadratic.InOut);
  }

  tweenSwapHeld(position, handSprite, tableSprite) {
    const heldSprite = this.sprites.held;

    const x = handSprite.x;
    const y = handSprite.y;

    tableSprite.x = x;
    tableSprite.y = y;
    tableSprite.rotation = posRotation(position);

    const heldTween = new Tween(heldSprite)
      .to({x, y}, 500)
      .easing(Easing.Quadratic.InOut)
      .onComplete(obj => {
        obj.visible = false;
        handSprite.visible = true;
      });

    const tableTween = new Tween(tableSprite)
      .to({x: TABLE_CARD_X, y: TABLE_CARD_Y, rotation: 0}, 700)
      .easing(Easing.Quadratic.InOut)
      .delay(200);

    return [heldTween, tableTween];
  }

  // client events

  onDeckClick() {
    this.pushEvent("deck-click", {playerId: this.game.playerId});
  }

  onTableClick() {
    this.pushEvent("table-click", {playerId: this.game.playerId});
  }

  onHandClick(playerId, handIndex) {
    this.pushEvent("hand-click", {playerId, handIndex});
  }

  onHeldClick() {
    this.pushEvent("held-click", {playerId: this.game.playerId});
  }

  // sprites

  addSprites() {
    this.addDeck();
    
    if (this.game.state) {
      this.addTableCards();
      
      for (const player of this.game.players) {
        this.addHand(player);

        if (player.heldCard) {
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

    // add the second card first, so it's on bottom
    if (card1) {
      this.addTableCard(card1);
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

      this.sprites.hands[player.position][i] = sprite;
      this.stage.addChild(sprite);

      const isPlayersCard = player.id === this.game.playerId;
      if (isPlayersCard && this.isPlayable(`hand_${i}`)) {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      }
    }
  }

  addHeldCard(player) {
    const texture = this.textures[player.heldCard];
    const coord = heldCardCoord(player.position);
    const sprite = makeCardSprite(texture, coord.x, coord.y, coord.rotation);
    
    this.sprites.held = sprite;
    this.stage.addChild(sprite);

    if (this.isPlayable("held")) {
      makePlayable(sprite, this.onHeldClick.bind(this));
    }

    return sprite;
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
  return state ? DECK_X : CENTER_X;
}

function posRotation(position) {
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

  const rotation = posRotation(position);
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

  const rotation = posRotation(position);
  return { x, y, rotation };
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

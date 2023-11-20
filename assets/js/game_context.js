import * as PIXI from "pixi.js";
import { update as updateTweens } from "@tweenjs/tween.js";

import {
  GAME_WIDTH, GAME_HEIGHT, TABLE_CARD_X, TABLE_CARD_Y, 
  handCardCoord, heldCardCoord
} from "./game_canvas";

import {
  makeCardSprite, makeDeckSprite, makePlayable, makeTableSprite, makeUnplayable
} from "./sprites";

import { 
  tweenDeck, tweenHand, tweenHeldDeck, tweenHeldTable, tweenTableDeck
} from "./tweens";

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
      hands: { bottom: [], left: [], top: [], right: [] },
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
    const texture = this.textures[DECK_CARD];
    const callback = this.isPlayable("deck") ? this.onDeckClick.bind(this) : null;
    const sprite = makeDeckSprite(texture, this.game.state, callback);

    this.sprites.deck = sprite;
    this.stage.addChild(sprite);
  }

  addTableCards() {
    const card0 = this.game.tableCards[0];
    const card1 = this.game.tableCards[1];

    // add the second card first, so it's on bottom
    if (card1) {
      const texture1 = this.textures[card1];
      const sprite1 = makeTableSprite(texture1);

      this.sprites.table.unshift(sprite1);
      this.stage.addChild(sprite1);
    }

    if (card0) {
      const texture0 = this.textures[card0];
      const callback = this.isPlayable("table") ? this.onTableClick.bind(this) : null;
      const sprite0 = makeTableSprite(texture0, callback);

      this.sprites.table.unshift(sprite0);
      this.stage.addChild(sprite0);
    }
  }

  addHand(player) {
    for (let i = 0; i < HAND_SIZE; i++) {
      const card = player.hand[i];
      const name = card["face_up?"] ? card.name : DOWN_CARD;

      const texture = this.textures[name];
      const coord = handCardCoord(player.position, i);
      const sprite = makeCardSprite(texture, coord.x, coord.y, coord.rotation);

      this.sprites.hands[player.position][i] = sprite;
      this.stage.addChild(sprite);

      if (player.id === this.game.playerId
        && this.isPlayable(`hand_${i}`)) {
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

  // server events

  onRoundStart(game) {
    this.game = game;

    for (const player of this.game.players) {
      this.addHand(player);
      const pos = player.position;

      tweenHand(pos, this.sprites.hands[pos])
        .forEach((tween, i) => {
          tween.start();

          // start tweening the deck after dealing the first row
          if (i === 2) {
            tween.onComplete(() => {
              tweenDeck(this.sprites.deck)
                .start()
                .onComplete(() => {
                  this.addTableCards();
                  tweenTableDeck(this.sprites.table[0]).start();
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

    const cardName = player.hand[event.hand_index]["name"];
    const handSprites = this.sprites.hands[player.position];

    const handSprite = handSprites[event.hand_index];
    handSprite.texture = this.textures[cardName];

    for (let i = 0; i < HAND_SIZE; i++) {
      if (!this.isPlayable(`hand_${i}`)) {
        makeUnplayable(handSprites[i]);
      }
    }

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, this.onDeckClick.bind(this));
    }

    // a player could flip a hand card before the table card is drawn so we also need to check if it exists
    if (this.sprites.table[0] && this.isPlayable("table")) {
      makePlayable(this.sprites.table[0], this.onTableClick.bind(this));
    }
  }

  onTakeFromDeck(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take from deck");

    const heldSprite = this.addHeldCard(player);

    tweenHeldDeck(player.position, heldSprite, this.sprites.deck).start();

    if (player.id === this.game.playerId) {
      makePlayable(heldSprite, this.onHeldClick.bind(this));
      makeUnplayable(this.sprites.deck);

      const tableSprite = this.sprites.table[0];
      if (tableSprite) {
        makeUnplayable(tableSprite);
      }

      this.sprites.hands[player.position].forEach((sprite, i) => {
        makePlayable(sprite, () => this.onHandClick(player.id, i));
      });
    }
  }

  onTakeFromTable(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on take from table");

    const heldSprite = this.addHeldCard(player);
    const tableSprite = this.sprites.table.shift();
    
    tweenHeldTable(player.position, heldSprite, tableSprite).start();

    if (player.id === this.game.playerId) {
      makeUnplayable(this.sprites.deck);
      makePlayable(heldSprite, this.onHeldClick.bind(this));

      this.sprites.hands[player.position].forEach((sprite, index) => {
        makePlayable(sprite, () => this.onHandClick(player.id, index));
      });
    }
  }

  onDiscard(event) {
    const player = this.game.players.find(p => p.id === event.player_id);
    if (!player) throw new Error("player is null on discard");

    this.addTableCards();
    this.sprites.held.visible = false;
    // tweenTableDiscard(player.position, this.sprites.table[0], this.sprites.held).start();

    this.sprites.hands[player.position].forEach((sprite, i) => {
      if (!this.isPlayable(`hand_${i}`)) {
        makeUnplayable(sprite);
      }

      // if the game is over, flip all the player's cards
      if (this.game.state === "over") {
        const name = player.hand[i].name;
        sprite.texture = this.textures[name];
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
    handSprite.visible = true;

    this.sprites.held.visible = false;

    const card0 = this.game.tableCards[0];
    const texture0 = this.textures[card0];

    let table0 = this.sprites.table[0];

    if (table0) {
      table0.texture = texture0;
      const card1 = this.game.tableCards[1];

      if (card1) {
        const table1 = this.sprites.table[1];
        const texture1 = this.textures[card1];

        if (table1) {
          table1.texture = this.textures[texture1];
        } else {
          const table1 = makeCardSprite(texture1, TABLE_CARD_X, TABLE_CARD_Y);
          this.sprites.table[1] = table1;
          this.stage.addChild(table1);

          makeUnplayable(table0);
          table0 = makeCardSprite(texture0, TABLE_CARD_X, TABLE_CARD_Y);
          this.sprites.table[0] = table0;
          this.stage.addChild(table0);
        }
      }
    } else {
      table0 = makeCardSprite(texture0, TABLE_CARD_X, TABLE_CARD_Y);
      this.sprites.table[0] = table0;
      this.stage.addChild(table0);
    }

    // const [heldTween, tableTween] = tweenSwapHeld(player.position, this.sprites.held, handSprite, table0);
    // heldTween.start();
    // tableTween.start();

    if (this.game.isFlipped) {
      handSprites.forEach((sprite, i) => {
        const card = player.hand[i]["name"];
        sprite.texture = this.textures[card];
      });
    }

    // if this is the current user's action make their hand unplayable
    if (player.id === this.game.playerId) {
      for (const sprite of handSprites) {
        makeUnplayable(sprite);
      }
    }

    if (this.isPlayable("deck")) {
      makePlayable(this.sprites.deck, this.onDeckClick.bind(this));
    }

    if (this.isPlayable("table")) {
      makePlayable(table0, this.onTableClick.bind(this));
    }
  }

  // client events

  onDeckClick() {
    this.pushEvent("deck-click", { playerId: this.game.playerId });
  }

  onTableClick() {
    this.pushEvent("table-click", { playerId: this.game.playerId });
  }

  onHandClick(playerId, handIndex) {
    this.pushEvent("hand-click", { playerId, handIndex });
  }

  onHeldClick() {
    this.pushEvent("held-click", { playerId: this.game.playerId });
  }

  // util

  isPlayable(place) {
    return this.game.playableCards.includes(place);
  }
}

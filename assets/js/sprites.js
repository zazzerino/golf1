import * as PIXI from "pixi.js";
import { OutlineFilter } from "@pixi/filter-outline";
import { CARD_SCALE, DECK_Y, TABLE_CARD_X, TABLE_CARD_Y, deckX } from "./game_canvas";

const PLAYABLE_FILTER = new OutlineFilter(2, 0xff00ff, 1.0);

export function makeCardSprite(texture, x = 0, y = 0, rotation = 0) {
  const sprite = PIXI.Sprite.from(texture);
  sprite.scale.set(CARD_SCALE, CARD_SCALE);
  sprite.anchor.set(0.5);
  sprite.x = x;
  sprite.y = y;
  sprite.rotation = rotation;
  return sprite;
}

export function makePlayable(sprite, callback) {
  sprite.eventMode = "static";
  sprite.cursor = "hover"
  sprite.filters = [PLAYABLE_FILTER];
  sprite.removeAllListeners();
  sprite.on("pointerdown", event => callback(event.currentTarget));
}

export function makeUnplayable(sprite) {
  sprite.eventMode = "none";
  sprite.cursor = "default";
  sprite.filters = [];
  sprite.removeAllListeners();
}

export function makeDeckSprite(texture, state, callback) {
  const x = deckX(state);
  const sprite = makeCardSprite(texture, x, DECK_Y);

  if (callback) {
    makePlayable(sprite, callback)
  }

  return sprite;
}

export function makeTableSprite(texture, callback) {
  const sprite = makeCardSprite(texture, TABLE_CARD_X, TABLE_CARD_Y);

  if (callback) {
    makePlayable(sprite, callback);
  }

  return sprite;
}

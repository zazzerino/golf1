import { Easing, Tween } from "@tweenjs/tween.js";

import { 
  rotationAt, 
  CENTER_X, DECK_X, DECK_Y, DECK_Y_OFFSET, TABLE_CARD_X, TABLE_CARD_Y, HAND_SIZE 
} from "./game_canvas";

export function tweenWiggle(sprite, duration = 150, distance = 1, repeats = 2) {
  const startX = sprite.x;

  const tweenReturn = new Tween(sprite)
    .to({ x: startX }, duration / 2)
    .easing(Easing.Quadratic.Out);

  sprite.x = startX - distance;

  return new Tween(sprite)
    .to({ x: startX + distance }, duration / repeats)
    .easing(Easing.Quintic.InOut)
    .repeat(repeats)
    .yoyo(true)
    .chain(tweenReturn);
}

export function handTweens(pos, handSprites) {
  const tweens = [];

  // start with the last card in the hand (bottom right)
  for (let i = HAND_SIZE-1; i >= 0; i--) {
    const sprite = handSprites[i];

    const x = sprite.x;
    const y = sprite.y;
    const rotation = rotationAt(pos)

    sprite.x = CENTER_X;
    sprite.y = DECK_Y + DECK_Y_OFFSET;
    sprite.rotation = 0;

    const tween = new Tween(sprite)
      .to({ x, y, rotation }, 800)
      .easing(Easing.Cubic.InOut)
      .delay((HAND_SIZE-1-i) * 150);

    tweens.push(tween);
  }

  return tweens;
}

export function tweenDeck(deckSprite) {
  return new Tween(deckSprite)
    .to({ x: DECK_X }, 200)
    .easing(Easing.Quadratic.Out);
}

export function tweenTable(tableSprite) {
  tableSprite.x = DECK_X;

  return new Tween(tableSprite)
    .to({ x: TABLE_CARD_X }, 400)
    .easing(Easing.Quadratic.Out);
}

export function tweenTakeDeck(pos, heldSprite, deckSprite) {
  const x = heldSprite.x;
  const y = heldSprite.y;
  const rotation = rotationAt(pos);

  heldSprite.x = deckSprite.x;
  heldSprite.y = deckSprite.y + DECK_Y_OFFSET;
  heldSprite.rotation = 0;

  return new Tween(heldSprite)
    .to({ x, y, rotation }, 750)
    .easing(Easing.Quadratic.InOut);
}

export function tweenTakeTable(pos, heldSprite, tableSprite) {
  const x = heldSprite.x;
  const y = heldSprite.y;
  const rotation = rotationAt(pos);

  heldSprite.x = tableSprite.x;
  heldSprite.y = tableSprite.y;
  heldSprite.rotation = 0;

  return new Tween(heldSprite)
    .onStart(() => tableSprite.visible = false)
    .to({ x, y, rotation }, 750)
    .easing(Easing.Quadratic.InOut);
}

export function tweenDiscard(pos, tableSprite, heldSprite) {
  heldSprite.visible = false;

  const x = tableSprite.x;
  const y = tableSprite.y;

  tableSprite.x = heldSprite.x;
  tableSprite.y = heldSprite.y;
  tableSprite.rotation = rotationAt(pos);

  return new Tween(tableSprite)
    .to({ x, y, rotation: 0 }, 750)
    .easing(Easing.Quadratic.InOut);
}

export function tweenSwapHeld(pos, heldSprite, handSprite, tableSprite) {
  const x = handSprite.x;
  const y = handSprite.y;

  tableSprite.x = x;
  tableSprite.y = y;
  tableSprite.rotation = rotationAt(pos);

  const heldTween = new Tween(heldSprite)
    .to({ x, y }, 500)
    .easing(Easing.Quadratic.InOut)
    .onComplete(obj => {
      obj.visible = false;
      handSprite.visible = true;
    });

  const tableTween = new Tween(tableSprite)
    .to({ x: TABLE_CARD_X, y: TABLE_CARD_Y, rotation: 0 }, 750)
    .easing(Easing.Quadratic.InOut)
    .delay(200);

  return [heldTween, tableTween];
}

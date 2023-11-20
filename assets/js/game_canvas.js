export const GAME_WIDTH = 600;
export const GAME_HEIGHT = 600;

export const CENTER_X = GAME_WIDTH / 2;
export const CENTER_Y = GAME_HEIGHT / 2;

export const CARD_IMG_WIDTH = 88;
export const CARD_IMG_HEIGHT = 124;

export const CARD_SCALE = 0.75;

export const CARD_WIDTH = CARD_IMG_WIDTH * CARD_SCALE;
export const CARD_HEIGHT = CARD_IMG_HEIGHT * CARD_SCALE;

export const DECK_X = CENTER_X - CARD_WIDTH / 2;
export const DECK_Y = CENTER_Y;

/**
The deck png has 5 pixels of cards below the top card.
This offset lets us place cards correctly on top of the deck.
*/
export const DECK_Y_OFFSET = -5;

export const TABLE_CARD_X = CENTER_X + CARD_WIDTH / 2 + 2;
export const TABLE_CARD_Y = CENTER_Y;

export const HAND_SIZE = 6;

export const HAND_X_PAD = 3;
export const HAND_Y_PAD = 10;

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

export function rotationAt(pos) {
  return pos == "left" || pos === "right"
    ? toRadians(90)
    : 0;
}

// sprite coords

export function deckX(state) {
  return state ? DECK_X : CENTER_X;
}

export function heldCardCoord(pos, yPad = HAND_Y_PAD) {
  let x, y;

  switch (pos) {
    case "bottom":
      x = CENTER_X + CARD_WIDTH * 2.5;
      y = GAME_HEIGHT - CARD_HEIGHT - yPad;
      break;

    case "left":
      x = CARD_HEIGHT + yPad;
      y = CENTER_Y + CARD_WIDTH * 2.75;
      break;

    case "top":
      x = CENTER_X - CARD_WIDTH * 2.5;
      y = CARD_HEIGHT + yPad;
      break;

    case "right":
      x = GAME_WIDTH - CARD_HEIGHT - yPad;
      y = CENTER_Y - CARD_WIDTH * 2.75
      break;
  }

  return { x, y, rotation: rotationAt(pos) }
}


export function handCardCoord(pos, index, xPad = HAND_X_PAD, yPad = HAND_Y_PAD) {
  let x = 0, y = 0;

  if (pos === "bottom") {
    switch (index) {
      case 0:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3;
        break;

      case 1:
        x = CENTER_X;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3;
        break;

      case 2:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = GAME_HEIGHT - CARD_HEIGHT * 1.5 - yPad * 1.3;
        break;

      case 3:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad;
        break;

      case 4:
        x = CENTER_X;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad;
        break;

      case 5:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = GAME_HEIGHT - CARD_HEIGHT / 2 - yPad;
        break;
    }
  } else if (pos === "top") {
    switch (index) {
      case 0:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = CARD_HEIGHT * 1.5 + yPad * 1.3;
        break;

      case 1:
        x = CENTER_X;
        y = CARD_HEIGHT * 1.5 + yPad * 1.3;
        break;

      case 2:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = CARD_HEIGHT * 1.5 + yPad * 1.3;
        break;

      case 3:
        x = CENTER_X + CARD_WIDTH + xPad;
        y = CARD_HEIGHT / 2 + yPad;
        break;

      case 4:
        x = CENTER_X;
        y = CARD_HEIGHT / 2 + yPad;
        break;

      case 5:
        x = CENTER_X - CARD_WIDTH - xPad;
        y = CARD_HEIGHT / 2 + yPad;
        break;
    }
  } else if (pos === "left") {
    switch (index) {
      case 0:
        x = CARD_HEIGHT * 1.5 + yPad * 1.3;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;

      case 1:
        x = CARD_HEIGHT * 1.5 + yPad * 1.3;
        y = CENTER_Y;
        break;

      case 2:
        x = CARD_HEIGHT * 1.5 + yPad * 1.3;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;

      case 3:
        x = CARD_HEIGHT / 2 + yPad;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;

      case 4:
        x = CARD_HEIGHT / 2 + yPad;
        y = CENTER_Y;
        break;

      case 5:
        x = CARD_HEIGHT / 2 + yPad;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;
    }
  } else if (pos === "right") {
    switch (index) {
      case 0:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPad * 1.3;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;

      case 1:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPad * 1.3;
        y = CENTER_Y;
        break;

      case 2:
        x = GAME_WIDTH - CARD_HEIGHT * 1.5 - yPad * 1.3;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;

      case 3:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPad;
        y = CENTER_Y + CARD_WIDTH + xPad;
        break;

      case 4:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPad;
        y = CENTER_Y;
        break;

      case 5:
        x = GAME_WIDTH - CARD_HEIGHT / 2 - yPad;
        y = CENTER_Y - CARD_WIDTH - xPad;
        break;
    }
  }

  return { x, y, rotation: rotationAt(pos) };
}

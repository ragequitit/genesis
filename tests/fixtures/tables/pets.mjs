// En hjalpare av VARJE art i spelets PETS-lista, sa hjalparfonstret visar alla bilder.
import { petKeys } from '../../helpers/source.mjs';
const keys = petKeys();
const rows = keys.map((sp, i) => ({
  id: '40000000-0000-4000-8000-' + String(i + 1).padStart(12, '0'),
  species: sp, rarity: i % 6, affixes: [], xp: 100 * i, nickname: null,
  team_slot: null, shiny: i === 4, traded_from: null, favorite: i === 1,
}));
// Tre EXTRA hjalpare sitter i laget (laget visas utanfor fonstret, sa de raknas inte bort ur listan).
keys.slice(0, 3).forEach((sp, i) => rows.push({
  id: '40000000-0000-4000-8000-9' + String(i + 1).padStart(11, '0'), species: sp, rarity: 3, affixes: [], xp: 500,
  nickname: null, team_slot: i, shiny: false, traded_from: null, favorite: false,
}));
export default () => rows;

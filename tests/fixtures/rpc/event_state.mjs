// Ett PAGAENDE Halloween-event (borjade i gar, slutar om en vecka), med butik och fynd.
const d = h => new Date(Date.now() + h * 3600e3).toISOString();
export default () => ({
  now: d(0), next: null,
  event: {
    key: 'halloween_2026', name: 'Halloween', tagline: 'The grid is haunted.', starts_at: d(-24), ends_at: d(24 * 7),
    accent: '#ff8c1a', flavor: 'Something grins.',
    mark: { key: 'halloween_mark', name: 'Jack-o’-Mark', plural: 'Jack-o’-Marks', art: 'assets/items/event/halloween_mark.webp' },
    set: { name: 'Jack-o’-Lantern', prefix: 'jack', figure_suffix: 'halloween', min: 5 },
    shop: [
      { key: 'jack_head', name: 'Jack-o’-Lantern Head', kind: 'appearance', price: 40, payload: { item_key: 'jack_head', slot: 0 }, art: 'assets/gear/halloween/jack_head.webp', descr: 'Appearance for the head slot.', per_char: 1, sort: 10, bought: 0, owned: false },
      { key: 'cache_rare', name: 'Rare Cache', kind: 'gear', price: 8, payload: { rarity: 2, up_chance: 0.25 }, art: 'assets/items/caches/cache_gear_rare.webp', descr: 'A Rare piece.', per_char: null, per_day: 1, bought_today: 0, sort: 70, bought: 0, owned: false },
      { key: 'helper_fang', name: 'Fang', kind: 'pet', price: 25, payload: {}, art: 'assets/pets/fang.webp', descr: 'A helper.', sort: 75, bought: 0, owned: false },
      { key: 'helper_howl', name: 'Howl', kind: 'pet', price: 25, payload: {}, art: 'assets/pets/howl.webp', descr: 'A helper.', sort: 76, bought: 0, owned: false },
      { key: 'boost_luck', name: 'Fortune Vial', kind: 'stack', price: 10, payload: { stack_key: 'boost_luck', qty: 1 }, art: 'assets/ui/boost/fortune_vial.webp', descr: 'A Luck Boost.', sort: 80, bought: 0, owned: false },
    ],
    drops: [
      { src: 'encounter', chance: 0.1, qty_min: 1, qty_max: 1, min_tier: 0 },
      { src: 'expedition', chance: 1, qty_min: 1, qty_max: 2, min_tier: 0, full_mins: 240 },
      { src: 'dungeon', chance: 1, qty_min: 2, qty_max: 2, min_tier: 0, first_bonus: 1 },
    ],
    marks: 37,
  },
});

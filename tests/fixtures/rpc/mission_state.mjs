// Uppdragstavlan. Tiderna raknas fran "nu", sa datan aldrig blir gammal.
const om = h => new Date(Date.now() + h * 3600e3).toISOString();
export default () => ({
  at_board: true, region: 'voxholm', region_name: 'Voxholm', level: 50, min_level: 10,
  credits: 120, cost: 25, bought: 1, per_region: 3, resets_at: om(10), hours: 24, lean_mins: 240, lean: null,
  lean_map: [{ region: 'voxholm', region_name: 'Voxholm', affixes: [{ key: 'gold', name: 'Gold Find' }] }],
  board: [
    { id: null, pos: 0, kind: 'kill', name: 'Pest Control', blurb: 'Clear the fields.', qty: 20, status: 'open', region: 'voxholm', region_name: 'Voxholm', reward: { gear_cache: 1 } },
    { id: '50000000-0000-4000-8000-000000000001', pos: 1, kind: 'gather', name: 'Ore Run', blurb: 'Bring ore.', qty: 50, progress: 20, status: 'active', expires_at: om(5), region: 'voxholm', region_name: 'Voxholm', reward: { helper_cache: 1, lean: true } },
    { id: '50000000-0000-4000-8000-000000000002', pos: 2, kind: 'dungeon', name: 'Deep Dive', blurb: 'Clear a dungeon.', qty: 1, progress: 1, status: 'ready', expires_at: om(3), region: 'voxholm', region_name: 'Voxholm', reward: { gear_cache: 2 } },
  ],
  active: [],
});

import { petKeys } from '../../helpers/source.mjs';
const rows = petKeys().map(sp => ({ species: sp, shiny_at: null }));
export default () => rows;

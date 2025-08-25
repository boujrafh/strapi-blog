// export default ({ env }) => ({
//   host: env('HOST', '0.0.0.0'),
//   port: env.int('PORT', 1440),
//   app: {
//     keys: env.array('APP_KEYS'),
//   },
// });

// config/server.js
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1440),
  url: env('SERVER_URL', 'https://cms.bh-systems.be'),
  app: { keys: env.array('APP_KEYS') },
});

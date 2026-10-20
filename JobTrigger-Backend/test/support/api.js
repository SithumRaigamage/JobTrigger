const request = require('supertest');

// Every suite talks to the one server test/setup.js starts, instead of
// supertest's request(app), which starts and closes a throwaway server per
// request. Rapid port reuse from those made roughly 1 run in 10 fail at a
// random test ("socket hang up", or a raw HTTP 400 on a bodyless GET).
let server;

exports.useServer = (instance) => {
  server = instance;
};

exports.api = () => {
  if (!server) throw new Error('test/setup.js has not started the server yet');
  return request(server);
};

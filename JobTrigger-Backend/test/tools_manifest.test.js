const fs = require('fs');
const path = require('path');
const { expect } = require('chai');

// The repo's one release manifest and this project's copy of it must be
// identical (scripts/sync-tools.mjs). A failure means someone edited one
// without running `node scripts/sync-tools.mjs`.
const source = path.join(__dirname, '..', '..', 'release', 'tools.json');
const copy = path.join(__dirname, '..', 'config', 'tools.json');

describe('Release manifest copy', function() {
  it('is byte-identical to release/tools.json', function() {
    expect(fs.readFileSync(copy, 'utf8')).to.equal(fs.readFileSync(source, 'utf8'));
  });
});

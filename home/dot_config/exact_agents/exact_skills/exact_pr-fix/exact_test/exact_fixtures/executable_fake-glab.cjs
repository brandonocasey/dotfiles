#!/usr/bin/env node

// The scenario format does not depend on the CLI, so glab reuses the gh fake.
// The chezmoi source names it with an `executable_` prefix.
const fs = require('fs');
const path = require('path');
const source = path.join(__dirname, 'executable_fake-gh.cjs');
require(fs.existsSync(source) ? source : './fake-gh.cjs');

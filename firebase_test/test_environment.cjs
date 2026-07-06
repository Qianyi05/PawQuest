const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const projectId = 'demo-pawquest';

async function createTestEnvironment() {
  return initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
    storage: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '..', 'storage.rules'),
        'utf8',
      ),
    },
  });
}

module.exports = {createTestEnvironment, projectId};

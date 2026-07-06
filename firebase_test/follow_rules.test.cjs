const {
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  writeBatch,
} = require('firebase/firestore');
const {createTestEnvironment} = require('./test_environment.cjs');

describe('follow mirror writes', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnvironment();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  it('allows a follower to create both mirror documents atomically', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    const batch = writeBatch(alice);
    batch.set(doc(alice, 'users/alice/following/bob'), {timestamp: 1});
    batch.set(doc(alice, 'users/bob/followers/alice'), {timestamp: 1});
    await assertSucceeds(batch.commit());
  });

  it('rejects a forged one-sided follow', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertFails(setDoc(
      doc(alice, 'users/bob/followers/alice'),
      {timestamp: 1},
    ));
  });

  it('allows both mirror documents to be removed atomically', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/alice/following/bob'), {timestamp: 1});
      await setDoc(doc(db, 'users/bob/followers/alice'), {timestamp: 1});
    });
    const alice = testEnv.authenticatedContext('alice').firestore();
    const batch = writeBatch(alice);
    batch.delete(doc(alice, 'users/alice/following/bob'));
    batch.delete(doc(alice, 'users/bob/followers/alice'));
    await assertSucceeds(batch.commit());
  });

  it('allows signed-in users to read follower counts', async () => {
    const carol = testEnv.authenticatedContext('carol').firestore();
    await assertSucceeds(getDoc(doc(carol, 'users/bob/followers/alice')));
  });
});

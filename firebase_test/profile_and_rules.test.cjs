const {strict: assert} = require('node:assert');
const {
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
} = require('firebase/firestore');
const {createTestEnvironment} = require('./test_environment.cjs');

describe('profile persistence and Firestore rules', () => {
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

  it('creates a missing profile and reads every saved field back', async () => {
    const alice = testEnv.authenticatedContext('alice', {
      email: 'alice@example.com',
    }).firestore();
    const profile = doc(alice, 'users/alice');

    await assertSucceeds(setDoc(profile, {
      nickname: 'Alice',
      bio: 'Walking across Italy',
      city: 'Milan',
      age: 24,
    }, {merge: true}));

    const saved = (await getDoc(profile)).data();
    assert.equal(saved.nickname, 'Alice');
    assert.equal(saved.bio, 'Walking across Italy');
    assert.equal(saved.city, 'Milan');
    assert.equal(saved.age, 24);
  });

  it('allows signed-in users to read a public profile', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'users/alice'), {
        nickname: 'Alice',
        bio: 'Hello',
      });
    });
    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertSucceeds(getDoc(doc(bob, 'users/alice')));
  });

  it('rejects unauthenticated profile reads and writes by another user', async () => {
    const guest = testEnv.unauthenticatedContext().firestore();
    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertFails(getDoc(doc(guest, 'users/alice')));
    await assertFails(setDoc(doc(bob, 'users/alice'), {nickname: 'Impostor'}));
  });

  for (const invalidAge of [0, 121, -1, 'twenty']) {
    it(`rejects invalid profile age: ${invalidAge}`, async () => {
      const alice = testEnv.authenticatedContext('alice').firestore();
      await assertFails(setDoc(doc(alice, 'users/alice'), {
        nickname: 'Alice',
        age: invalidAge,
      }));
    });
  }

  it('allows an empty age to be stored as null', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(setDoc(doc(alice, 'users/alice'), {
      nickname: 'Alice',
      age: null,
    }));
  });
});

const {strict: assert} = require('node:assert');
const {deleteApp, initializeApp} = require('firebase/app');
const {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} = require('firebase/auth');
const {
  connectFirestoreEmulator,
  doc,
  getDoc,
  getFirestore,
  setDoc,
} = require('firebase/firestore');
const {createTestEnvironment, projectId} = require('./test_environment.cjs');

describe('Auth to profile end-to-end flow', () => {
  let testEnv;
  let app;
  let auth;
  let db;

  before(async () => {
    testEnv = await createTestEnvironment();
    app = initializeApp({
      apiKey: 'demo-key',
      appId: 'demo-app',
      projectId,
      authDomain: `${projectId}.firebaseapp.com`,
    }, 'auth-profile-flow');
    auth = getAuth(app);
    db = getFirestore(app);
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', {
      disableWarnings: true,
    });
    connectFirestoreEmulator(db, '127.0.0.1', 8080);
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  after(async () => {
    await signOut(auth);
    await deleteApp(app);
    await testEnv.cleanup();
  });

  it('registers, saves a complete profile, signs back in, and reads it', async () => {
    const email = `profile-${Date.now()}@example.com`;
    const password = 'Test-password-123';
    const credential = await createUserWithEmailAndPassword(
      auth,
      email,
      password,
    );
    const profileRef = doc(db, 'users', credential.user.uid);
    await setDoc(profileRef, {
      email,
      nickname: 'Emulator Walker',
      bio: 'Testing the complete profile flow',
      city: 'Rome',
      age: 28,
    }, {merge: true});

    await signOut(auth);
    await signInWithEmailAndPassword(auth, email, password);
    const saved = (await getDoc(profileRef)).data();

    assert.equal(saved.nickname, 'Emulator Walker');
    assert.equal(saved.bio, 'Testing the complete profile flow');
    assert.equal(saved.city, 'Rome');
    assert.equal(saved.age, 28);
  });
});

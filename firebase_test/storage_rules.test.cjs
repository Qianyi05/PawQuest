const {
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  getBytes,
  ref,
  uploadBytes,
} = require('firebase/storage');
const {createTestEnvironment} = require('./test_environment.cjs');

describe('avatar Storage rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnvironment();
  });

  beforeEach(async () => {
    await testEnv.clearStorage();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  it('allows an owner to upload an image and permits public reads', async () => {
    const aliceStorage = testEnv.authenticatedContext('alice').storage();
    const avatar = ref(aliceStorage, 'avatars/alice/avatar.jpg');
    await assertSucceeds(uploadBytes(
      avatar,
      Uint8Array.from([1, 2, 3]),
      {contentType: 'image/jpeg'},
    ));
    const guestStorage = testEnv.unauthenticatedContext().storage();
    await assertSucceeds(getBytes(
      ref(guestStorage, 'avatars/alice/avatar.jpg'),
    ));
  });

  it('rejects uploads to another user path or with a non-image type', async () => {
    const aliceStorage = testEnv.authenticatedContext('alice').storage();
    await assertFails(uploadBytes(
      ref(aliceStorage, 'avatars/bob/avatar.jpg'),
      Uint8Array.from([1]),
      {contentType: 'image/jpeg'},
    ));
    await assertFails(uploadBytes(
      ref(aliceStorage, 'avatars/alice/avatar.txt'),
      Uint8Array.from([1]),
      {contentType: 'text/plain'},
    ));
  });
});

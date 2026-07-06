const {strict: assert} = require('node:assert');
const {
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  addDoc,
  collection,
  doc,
  getDoc,
  runTransaction,
  setDoc,
  updateDoc,
  writeBatch,
} = require('firebase/firestore');
const {createTestEnvironment} = require('./test_environment.cjs');

describe('forum, comments, and notifications', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnvironment();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'posts/post-1'), {
        authorId: 'bob',
        content: 'A walk in Rome',
        likedBy: [],
        likes: 0,
      });
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  it('atomically adds a like and its author notification', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(runTransaction(alice, async (transaction) => {
      const postRef = doc(alice, 'posts/post-1');
      const post = await transaction.get(postRef);
      const likedBy = [...post.data().likedBy, 'alice'];
      transaction.update(postRef, {likedBy, likes: likedBy.length});
      transaction.set(doc(alice, 'users/bob/notifications/like-1'), {
        type: 'like',
        postId: 'post-1',
        actorId: 'alice',
        read: false,
      });
    }));

    const post = (await getDoc(doc(alice, 'posts/post-1'))).data();
    assert.deepEqual(post.likedBy, ['alice']);
    assert.equal(post.likes, 1);
  });

  it('rejects forged notifications and author-only post edits', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(alice, 'users/bob/notifications/fake'), {
      type: 'like',
      actorId: 'mallory',
      read: false,
    }));
    await assertFails(updateDoc(doc(alice, 'posts/post-1'), {
      content: 'Changed by somebody else',
    }));
  });

  it('allows a signed-in user to comment but not impersonate its author', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(addDoc(collection(alice, 'posts/post-1/comments'), {
      authorId: 'alice',
      content: 'Beautiful!',
    }));
    await assertFails(addDoc(collection(alice, 'posts/post-1/comments'), {
      authorId: 'bob',
      content: 'Forged comment',
    }));
  });

  it('atomically creates a comment and its notification', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    const batch = writeBatch(alice);
    batch.set(doc(alice, 'posts/post-1/comments/comment-1'), {
      authorId: 'alice',
      authorName: 'Alice',
      content: 'A lovely route',
    });
    batch.set(doc(alice, 'users/bob/notifications/comment-1'), {
      type: 'comment',
      postId: 'post-1',
      actorId: 'alice',
      actorName: 'Alice',
      commentText: 'A lovely route',
      read: false,
    });
    await assertSucceeds(batch.commit());

    const comment = await getDoc(
      doc(alice, 'posts/post-1/comments/comment-1'),
    );
    assert.equal(comment.data().content, 'A lovely route');
  });
});

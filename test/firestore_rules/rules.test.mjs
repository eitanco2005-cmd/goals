// Security-rules tests for ../../firestore.rules.
//
//   cd test/firestore_rules && npm install && npm test
//
// The writes below mirror exactly what lib/data/firebase/firebase_backend.dart
// does, so a rules change that breaks the app fails here.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Bytes,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;
const db = (uid) => env.authenticatedContext(uid).firestore();
const stamp = () => ({ updatedAt: serverTimestamp() });

const PAIR = 'pair1';
const CODE = 'ABC234';
const CH = 'ch1';
const DATE = '2026-11-15';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-goals',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// --- app operations (mirrors FirebaseBackend) -----------------------------
async function signUp(uid, name = uid) {
  await setDoc(doc(db(uid), `users/${uid}`), {
    uid, displayName: name, languageCode: 'he', pairId: null, ...stamp(),
  });
}

function createPair(uid, { pairId = PAIR, code = CODE } = {}) {
  const f = db(uid);
  return runTransaction(f, async (tx) => {
    await tx.get(doc(f, `users/${uid}`));
    await tx.get(doc(f, `inviteCodes/${code}`));
    tx.set(doc(f, `pairs/${pairId}`), {
      id: pairId, memberUids: [uid], memberNames: { [uid]: uid }, inviteCode: code,
      activeChallengeId: CH, createdBy: uid, ...stamp(),
    });
    tx.set(doc(f, `pairs/${pairId}/challenges/${CH}`), {
      id: CH, pairId, startDate: '2026-11-15', endDate: '2026-12-14', goals: [], ...stamp(),
    });
    tx.set(doc(f, `inviteCodes/${code}`), { pairId, open: true, createdBy: uid });
    tx.update(doc(f, `users/${uid}`), { pairId, ...stamp() });
  });
}

function joinPair(uid, { code = CODE, closeInvite = true, setProfile = true } = {}) {
  const f = db(uid);
  return runTransaction(f, async (tx) => {
    await tx.get(doc(f, `users/${uid}`));
    const invite = await tx.get(doc(f, `inviteCodes/${code}`));
    const pairRef = doc(f, `pairs/${invite.data().pairId}`);
    const pair = (await tx.get(pairRef)).data();
    tx.update(pairRef, {
      memberUids: [...pair.memberUids, uid], [`memberNames.${uid}`]: uid, ...stamp(),
    });
    if (closeInvite) tx.update(doc(f, `inviteCodes/${code}`), { open: false });
    if (setProfile) tx.update(doc(f, `users/${uid}`), { pairId: pair.id, ...stamp() });
  });
}

function setGoal(uid, { owner = uid, date = DATE, goalId = 'water', value = 8 } = {}) {
  const f = db(uid);
  const batch = writeBatch(f);
  batch.set(doc(f, `pairs/${PAIR}/logs/${owner}/days/${date}`),
    { uid: owner, date, values: { [goalId]: value ?? deleteField() }, ...stamp() }, { merge: true });
  batch.set(doc(f, `pairs/${PAIR}/summaries/${owner}_${date}`),
    { uid: owner, date, statuses: { [goalId]: 'met' }, percent: 11, ...stamp() });
  return batch.commit();
}

const workout = (uid, id = 'w1') => ({
  id, uid, date: DATE, type: 'run', minutes: 35, ...stamp(),
});

async function pairedAliceBob() {
  await signUp('alice');
  await signUp('bob');
  await createPair('alice');
  await joinPair('bob');
}

// --- tests ----------------------------------------------------------------
describe('users', () => {
  it('owner can create/read/update own profile; others cannot read it', async () => {
    await assertSucceeds(signUp('alice'));
    await assertSucceeds(getDoc(doc(db('alice'), 'users/alice')));
    await assertSucceeds(updateDoc(doc(db('alice'), 'users/alice'), { languageCode: 'en' }));
    await assertFails(getDoc(doc(db('bob'), 'users/alice')));
    await assertFails(setDoc(doc(db('bob'), 'users/alice'), { uid: 'alice', displayName: 'x' }));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice')));
  });

  it('partner cannot read the other profile even when paired', async () => {
    await pairedAliceBob();
    await assertFails(getDoc(doc(db('bob'), 'users/alice')));
  });

  it('setLanguage (with stamp) succeeds; unknown language is rejected', async () => {
    await signUp('alice');
    const ref = doc(db('alice'), 'users/alice');
    await assertSucceeds(updateDoc(ref, { languageCode: 'en', ...stamp() }));
    await assertFails(updateDoc(ref, { languageCode: 'fr', ...stamp() }));
  });

  it('display name longer than 100 characters is rejected', async () => {
    await signUp('alice');
    const ref = doc(db('alice'), 'users/alice');
    await assertSucceeds(updateDoc(ref, { displayName: 'a'.repeat(100), ...stamp() }));
    await assertFails(updateDoc(ref, { displayName: 'a'.repeat(101), ...stamp() }));
  });

  it('cannot point pairId at a pair you are not in', async () => {
    await signUp('alice');
    await signUp('mallory');
    await createPair('alice');
    await assertFails(updateDoc(doc(db('mallory'), 'users/mallory'), { pairId: PAIR }));
  });
});

describe('pairing', () => {
  it('create pair transaction succeeds', async () => {
    await signUp('alice');
    await assertSucceeds(createPair('alice'));
  });

  it('cannot create a pair with someone else as member', async () => {
    await signUp('alice');
    await assertFails(setDoc(doc(db('alice'), 'pairs/p2'), {
      id: 'p2', memberUids: ['bob'], memberNames: { bob: 'b' }, inviteCode: 'X', createdBy: 'alice',
    }));
  });

  it('cannot hijack an existing invite code', async () => {
    await signUp('alice');
    await signUp('mallory');
    await createPair('alice');
    await assertFails(setDoc(doc(db('mallory'), `inviteCodes/${CODE}`), {
      pairId: 'evil', open: true, createdBy: 'mallory',
    }));
  });

  it('invite codes can be fetched but not listed', async () => {
    await signUp('alice');
    await createPair('alice');
    await assertSucceeds(getDoc(doc(db('bob'), `inviteCodes/${CODE}`)));
    await assertFails(getDocs(collection(db('bob'), 'inviteCodes')));
  });

  it('partner joins with the join transaction', async () => {
    await signUp('alice');
    await signUp('bob');
    await createPair('alice');
    await assertSucceeds(joinPair('bob'));
    const pair = (await getDoc(doc(db('alice'), `pairs/${PAIR}`))).data();
    if (pair.memberUids.length !== 2) throw new Error('not joined');
  });

  it('join must close the invite code', async () => {
    await signUp('alice');
    await signUp('bob');
    await createPair('alice');
    await assertFails(joinPair('bob', { closeInvite: false }));
  });

  it('third person cannot join or read a full pair', async () => {
    await pairedAliceBob();
    await signUp('carol');
    await assertFails(getDoc(doc(db('carol'), `pairs/${PAIR}`)));
    await assertFails(updateDoc(doc(db('carol'), `pairs/${PAIR}`), {
      memberUids: ['alice', 'bob', 'carol'],
    }));
  });

  it('joiner cannot change other fields', async () => {
    await signUp('alice');
    await signUp('bob');
    await createPair('alice');
    const f = db('bob');
    await assertFails(runTransaction(f, async (tx) => {
      tx.update(doc(f, `pairs/${PAIR}`), {
        memberUids: ['alice', 'bob'], 'memberNames.bob': 'b', inviteCode: 'ZZZZZZ',
      });
      tx.update(doc(f, `inviteCodes/${CODE}`), { open: false });
    }));
  });

  it('a member cannot remove the partner', async () => {
    await pairedAliceBob();
    await assertFails(updateDoc(doc(db('alice'), `pairs/${PAIR}`), { memberUids: ['alice'] }));
  });

  it('setDisplayName: profile + own memberNames entry', async () => {
    await pairedAliceBob();
    const f = db('alice');
    await assertSucceeds(updateDoc(doc(f, 'users/alice'), { displayName: 'Eitan', ...stamp() }));
    await assertSucceeds(updateDoc(doc(f, `pairs/${PAIR}`), { 'memberNames.alice': 'Eitan', ...stamp() }));
    // Not the partner's name, not a non-string, not too long.
    await assertFails(updateDoc(doc(f, `pairs/${PAIR}`), { 'memberNames.bob': 'x', ...stamp() }));
    await assertFails(updateDoc(doc(f, `pairs/${PAIR}`), { 'memberNames.alice': 42, ...stamp() }));
    await assertFails(updateDoc(doc(f, `pairs/${PAIR}`), { 'memberNames.alice': { x: 1 }, ...stamp() }));
    await assertFails(updateDoc(doc(f, `pairs/${PAIR}`), { 'memberNames.alice': 'a'.repeat(101), ...stamp() }));
  });

  it('members can switch the active challenge (createChallenge batch)', async () => {
    await pairedAliceBob();
    const f = db('bob');
    const batch = writeBatch(f);
    batch.set(doc(f, `pairs/${PAIR}/challenges/ch2`), {
      id: 'ch2', pairId: PAIR, startDate: '2027-01-01', endDate: '2027-01-31', goals: [], ...stamp(),
    });
    batch.update(doc(f, `pairs/${PAIR}`), { activeChallengeId: 'ch2', ...stamp() });
    await assertSucceeds(batch.commit());
    await assertSucceeds(getDoc(doc(db('alice'), `pairs/${PAIR}/challenges/ch2`)));
    await assertFails(getDoc(doc(db('carol'), `pairs/${PAIR}/challenges/ch2`)));
  });

  it('challenges cannot be deleted', async () => {
    await pairedAliceBob();
    await assertFails(deleteDoc(doc(db('alice'), `pairs/${PAIR}/challenges/${CH}`)));
  });

  it('challenge goals must be a list of maps (at most 30)', async () => {
    await pairedAliceBob();
    const ch = (goals) => setDoc(doc(db('alice'), `pairs/${PAIR}/challenges/ch3`), {
      id: 'ch3', pairId: PAIR, startDate: '2027-01-01', endDate: '2027-01-31', goals, ...stamp(),
    });
    await assertFails(ch([1, 2]));
    await assertFails(ch('water'));
    await assertFails(ch(Array.from({ length: 31 }, (_, i) => ({ id: `g${i}` }))));
    await assertSucceeds(ch([{ id: 'water', period: 'daily' }]));
  });
});

describe('logs, summaries, workouts', () => {
  beforeEach(pairedAliceBob);

  it('owner logs a value (log + summary batch) and clears it', async () => {
    await assertSucceeds(setGoal('alice'));
    await assertSucceeds(setGoal('alice', { value: null }));
    await assertSucceeds(getDoc(doc(db('alice'), `pairs/${PAIR}/logs/alice/days/${DATE}`)));
  });

  it('clearing a value with no log doc is rejected, so the app skips that write', async () => {
    await assertFails(setGoal('alice', { date: '2026-11-20', value: null }));
  });

  it('partner can NOT read the private log, but can read the summary', async () => {
    await setGoal('alice');
    await assertFails(getDoc(doc(db('bob'), `pairs/${PAIR}/logs/alice/days/${DATE}`)));
    await assertSucceeds(getDoc(doc(db('bob'), `pairs/${PAIR}/summaries/alice_${DATE}`)));
    await assertSucceeds(getDocs(query(collection(db('bob'), `pairs/${PAIR}/summaries`),
      where('uid', '==', 'alice'), where('date', '>=', '2026-11-01'),
      where('date', '<=', '2026-11-30'), orderBy('date'))));
  });

  it('partner cannot write my log or summary', async () => {
    await assertFails(setGoal('bob', { owner: 'alice' }));
    await assertFails(setDoc(doc(db('bob'), `pairs/${PAIR}/summaries/alice_${DATE}`),
      { uid: 'bob', date: DATE, statuses: {}, percent: 100 }));
  });

  it('outsiders see nothing', async () => {
    await setGoal('alice');
    await assertFails(getDoc(doc(db('carol'), `pairs/${PAIR}/summaries/alice_${DATE}`)));
    await assertFails(setGoal('carol', { owner: 'carol' }));
  });

  it('summary percent is validated', async () => {
    await assertFails(setDoc(doc(db('alice'), `pairs/${PAIR}/summaries/alice_${DATE}`),
      { uid: 'alice', date: DATE, statuses: {}, percent: 140 }));
  });

  it('workouts: own entries only', async () => {
    const ref = (f, id = 'w1') => doc(f, `pairs/${PAIR}/workouts/${id}`);
    await assertSucceeds(setDoc(ref(db('alice')), workout('alice')));
    await assertSucceeds(getDoc(ref(db('bob'))));
    await assertSucceeds(getDocs(query(collection(db('bob'), `pairs/${PAIR}/workouts`),
      where('uid', '==', 'alice'), where('date', '>=', DATE), where('date', '<=', DATE),
      orderBy('date'))));
    await assertFails(setDoc(ref(db('bob')), workout('bob'))); // overwrite alice's
    await assertFails(setDoc(ref(db('bob'), 'w2'), workout('alice', 'w2')));
    await assertFails(deleteDoc(ref(db('bob'))));
    await assertSucceeds(deleteDoc(ref(db('alice'))));
    await assertFails(setDoc(ref(db('carol'), 'w3'), workout('carol', 'w3')));
  });
});

// --- photos (mirrors FirebaseBackend.addPhoto / deletePhoto / setReaction) --
const bytes = (n) => Bytes.fromUint8Array(new Uint8Array(n).fill(7));

function photoMeta(uid, id, overrides = {}) {
  return {
    id, uid, date: DATE, goalId: 'veggies', createdAt: 1763200000000,
    thumbnail: bytes(20 * 1024), width: 1080, height: 1350, reactions: {},
    ...stamp(), ...overrides,
  };
}

function addPhoto(uid, { id = 'ph1', owner = uid, meta = {}, data = {}, withData = true,
  withMeta = true } = {}) {
  const f = db(uid);
  const batch = writeBatch(f);
  if (withData) {
    batch.set(doc(f, `pairs/${PAIR}/photoData/${id}`),
      { uid: owner, date: DATE, data: bytes(100 * 1024), ...stamp(), ...data });
  }
  if (withMeta) batch.set(doc(f, `pairs/${PAIR}/photos/${id}`), photoMeta(owner, id, meta));
  return batch.commit();
}

function deletePhoto(uid, id = 'ph1') {
  const f = db(uid);
  const batch = writeBatch(f);
  batch.delete(doc(f, `pairs/${PAIR}/photos/${id}`));
  batch.delete(doc(f, `pairs/${PAIR}/photoData/${id}`));
  return batch.commit();
}

const react = (uid, emoji, { id = 'ph1', key = uid } = {}) =>
  updateDoc(doc(db(uid), `pairs/${PAIR}/photos/${id}`),
    { [`reactions.${key}`]: emoji ?? deleteField(), ...stamp() });

describe('photos', () => {
  beforeEach(pairedAliceBob);

  it('owner adds a photo (metadata + data batch); both members read it', async () => {
    await assertSucceeds(addPhoto('alice'));
    for (const uid of ['alice', 'bob']) {
      await assertSucceeds(getDoc(doc(db(uid), `pairs/${PAIR}/photos/ph1`)));
      await assertSucceeds(getDoc(doc(db(uid), `pairs/${PAIR}/photoData/ph1`)));
    }
    // The app's watchPhotos queries (pair-wide and per user).
    const col = collection(db('bob'), `pairs/${PAIR}/photos`);
    await assertSucceeds(getDocs(query(col, where('date', '>=', DATE),
      where('date', '<=', DATE), orderBy('date'), orderBy('createdAt'))));
    await assertSucceeds(getDocs(query(col, where('uid', '==', 'alice'),
      where('date', '>=', DATE), where('date', '<=', DATE), orderBy('date'),
      orderBy('createdAt'))));
  });

  it('outsiders cannot read or add photos', async () => {
    await addPhoto('alice');
    await assertFails(getDoc(doc(db('carol'), `pairs/${PAIR}/photos/ph1`)));
    await assertFails(getDoc(doc(db('carol'), `pairs/${PAIR}/photoData/ph1`)));
    await assertFails(getDocs(collection(db('carol'), `pairs/${PAIR}/photos`)));
    await assertFails(addPhoto('carol', { id: 'ph2' }));
  });

  it('cannot add a photo in the partner\'s name', async () => {
    await assertFails(addPhoto('bob', { owner: 'alice' }));
    await assertFails(addPhoto('bob', { data: { uid: 'alice' } }));
    await assertFails(addPhoto('bob', { meta: { uid: 'alice' } }));
  });

  it('metadata and full image must be written together', async () => {
    await assertFails(addPhoto('alice', { withData: false }));
    await assertFails(addPhoto('alice', { withMeta: false }));
  });

  it('oversize thumbnail or full image is rejected', async () => {
    await assertSucceeds(addPhoto('alice', {
      id: 'max', meta: { thumbnail: bytes(60 * 1024) }, data: { data: bytes(800 * 1024) },
    }));
    await assertFails(addPhoto('alice', { id: 'big1', meta: { thumbnail: bytes(60 * 1024 + 1) } }));
    await assertFails(addPhoto('alice', { id: 'big2', data: { data: bytes(800 * 1024 + 1) } }));
  });

  it('photo fields are validated', async () => {
    const bad = [
      { date: 20261115 },
      { date: '15/11/2026' },
      { goalId: 7 },
      { thumbnail: 'not bytes' },
      { width: 10.5 },
      { height: '1350' },
      { createdAt: '2026-11-15' },
      { reactions: { bob: '❤️' } },
      { id: 'other' },
      { extra: true },
    ];
    for (const [i, meta] of bad.entries()) {
      await assertFails(addPhoto('alice', { id: `bad${i}`, meta }));
    }
    await assertFails(addPhoto('alice', { id: 'bad-data', data: { data: 'not bytes' } }));
  });

  it('only the owner deletes; the full image cannot be changed', async () => {
    await addPhoto('alice');
    await assertFails(deletePhoto('bob'));
    await assertFails(deleteDoc(doc(db('bob'), `pairs/${PAIR}/photoData/ph1`)));
    await assertFails(updateDoc(doc(db('alice'), `pairs/${PAIR}/photoData/ph1`),
      { data: bytes(10) }));
    await assertSucceeds(deletePhoto('alice'));
  });

  it('partner reacts, changes and removes the reaction', async () => {
    await addPhoto('alice');
    await assertSucceeds(react('bob', '❤️'));
    await assertSucceeds(react('bob', '🔥'));
    await assertSucceeds(react('bob', '💪'));
    const snap = await getDoc(doc(db('alice'), `pairs/${PAIR}/photos/ph1`));
    if (snap.data().reactions.bob !== '💪') throw new Error('reaction not stored');
    await assertSucceeds(react('bob', null));
  });

  it('reacting to a deleted photo is permission-denied; reading it shows it is gone', async () => {
    // FirebaseBackend.setReaction relies on both to treat this as a no-op.
    await addPhoto('alice');
    await deletePhoto('alice');
    const err = await assertFails(react('bob', '❤️'));
    if (err.code !== 'permission-denied') throw new Error(`got ${err.code}`);
    const snap = await assertSucceeds(getDoc(doc(db('bob'), `pairs/${PAIR}/photos/ph1`)));
    if (snap.exists()) throw new Error('photo still exists');
  });

  it('reactions: no unknown emoji, not on own photo, not for someone else', async () => {
    await addPhoto('alice');
    await assertFails(react('bob', '👍'));
    await assertFails(react('bob', 'x'.repeat(5000)));
    await assertFails(react('alice', '❤️')); // owner on own photo
    await assertFails(react('bob', '❤️', { key: 'alice' }));
    await assertFails(react('carol', '❤️')); // outsider
  });

  it('partner cannot modify anything but their reaction', async () => {
    await addPhoto('alice');
    const ref = doc(db('bob'), `pairs/${PAIR}/photos/ph1`);
    await assertFails(updateDoc(ref, { goalId: 'water', ...stamp() }));
    await assertFails(updateDoc(ref, { thumbnail: bytes(10) }));
    await assertFails(updateDoc(ref, { 'reactions.bob': '❤️', date: '2026-11-16' }));
    await assertFails(updateDoc(ref, { reactions: deleteField() }));
    // Neither can the owner (photos are immutable apart from reactions).
    await assertFails(updateDoc(doc(db('alice'), `pairs/${PAIR}/photos/ph1`),
      { goalId: 'water' }));
  });
});

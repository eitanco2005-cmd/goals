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
});

describe('logs, summaries, workouts', () => {
  beforeEach(pairedAliceBob);

  it('owner logs a value (log + summary batch) and clears it', async () => {
    await assertSucceeds(setGoal('alice'));
    await assertSucceeds(setGoal('alice', { value: null }));
    await assertSucceeds(getDoc(doc(db('alice'), `pairs/${PAIR}/logs/alice/days/${DATE}`)));
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

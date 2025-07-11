const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  // 사용자 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '사용자 인증이 필요합니다.');
  }

  const uid = context.auth.uid;
  const { confirmDelete } = data;

  // 삭제 확인 체크
  if (!confirmDelete) {
    throw new functions.https.HttpsError('invalid-argument', '삭제 확인이 필요합니다.');
  }

  try {
    console.log(`사용자 계정 삭제 시작: ${uid}`);

    // 1. Firestore에서 사용자 데이터 삭제
    await deleteUserData(uid);
    console.log(`사용자 데이터 삭제 완료: ${uid}`);

    // 2. Auth에서 사용자 계정 삭제
    await auth.deleteUser(uid);
    console.log(`사용자 계정 삭제 완료: ${uid}`);

    return { success: true, message: '계정이 성공적으로 삭제되었습니다.' };

  } catch (error) {
    console.error('계정 삭제 오류:', error);
    throw new functions.https.HttpsError('internal', '계정 삭제 중 오류가 발생했습니다.', error.message);
  }
});

async function deleteUserData(uid) {
  const batch = db.batch();
  
  try {
    // 사용자 메인 문서 참조
    const userDocRef = db.collection('users').doc(uid);
    
    // 하위 컬렉션들 삭제
    const subCollections = [
      'brain_health_history',
      'notifications', 
      'game_sessions',
      'achievements'
    ];

    for (const collectionName of subCollections) {
      const subCollectionRef = userDocRef.collection(collectionName);
      const snapshot = await subCollectionRef.get();
      
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
    }

    // 사용자 메인 문서 삭제
    batch.delete(userDocRef);
    
    // 배치 작업 실행
    await batch.commit();
    console.log('사용자 데이터 삭제 완료');

  } catch (error) {
    console.error('사용자 데이터 삭제 오류:', error);
    throw error;
  }
} 
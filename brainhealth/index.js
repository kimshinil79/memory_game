/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// 게임 결과 저장 및 브레인 헬스 인덱스 업데이트
exports.saveGameResult = functions.https.onCall(async (data, context) => {
  // 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const userId = context.auth.uid;
    const { gridSize, timeSpent, matchesFound, score } = data;

    // Firestore 참조 가져오기
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User document not found');
    }

    const userData = userDoc.data();
    let brainHealth = userData.brain_health || {};
    
    // 기존 통계 업데이트
    const totalGamesPlayed = (brainHealth.totalGamesPlayed || 0) + 1;
    const totalMatchesFound = (brainHealth.totalMatchesFound || 0) + matchesFound;
    
    // 최고 기록 업데이트
    const bestTimesByGridSize = brainHealth.bestTimesByGridSize || {};
    if (!bestTimesByGridSize[gridSize] || timeSpent < bestTimesByGridSize[gridSize]) {
      bestTimesByGridSize[gridSize] = timeSpent;
    }

    // 전체 최고 기록 업데이트
    const bestTime = Math.min(timeSpent, brainHealth.bestTime || Infinity);

    // 브레인 헬스 인덱스 계산
    const age = userData.age || 30;
    const ageComponent = Math.max(0, (100 - age) / 2); // 나이에 따른 기본 점수
    const activityComponent = Math.min(30, totalGamesPlayed); // 활동량 점수
    const performanceComponent = Math.min(40, (score / 1000) * 40); // 게임 성과 점수
    
    // 지속성 보너스 계산
    const now = new Date();
    const lastGameTime = brainHealth.lastUpdated?.toDate() || new Date(0);
    const daysSinceLastGame = Math.floor((now - lastGameTime) / (1000 * 60 * 60 * 24));
    const persistenceBonus = daysSinceLastGame <= 1 ? 10 : 0; // 매일 게임할 경우 보너스

    // 비활동 패널티 계산
    const inactivityPenalty = Math.min(daysSinceLastGame * 2, 20);

    // 최종 브레인 헬스 인덱스 계산
    const brainHealthIndex = Math.min(100,
      ageComponent +
      activityComponent +
      performanceComponent +
      persistenceBonus -
      inactivityPenalty
    );

    // 브레인 헬스 레벨 계산
    let brainHealthIndexLevel;
    if (brainHealthIndex < 35) brainHealthIndexLevel = 1;
    else if (brainHealthIndex < 60) brainHealthIndexLevel = 2;
    else if (brainHealthIndex < 80) brainHealthIndexLevel = 3;
    else if (brainHealthIndex < 95) brainHealthIndexLevel = 4;
    else brainHealthIndexLevel = 5;

    // Firestore 업데이트
    await userRef.update({
      'brain_health': {
        brainHealthIndex,
        brainHealthIndexLevel,
        totalGamesPlayed,
        totalMatchesFound,
        bestTimesByGridSize,
        bestTime: bestTime === Infinity ? 0 : bestTime,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        ageComponent,
        activityComponent,
        performanceComponent,
        persistenceBonus,
        inactivityPenalty,
        daysSinceLastGame
      }
    });

    return {
      success: true,
      brainHealthIndex,
      brainHealthIndexLevel
    };

  } catch (error) {
    console.error('Error saving game result:', error);
    throw new functions.https.HttpsError('internal', 'Error saving game result');
  }
});

// 사용자 랭킹 조회
exports.getUserRankings = functions.https.onCall(async (data, context) => {
  try {
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .orderBy('brain_health.brainHealthIndex', 'desc')
      .limit(100)
      .get();

    const rankings = [];
    let currentUserRank = null;
    let rank = 1;

    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      const ranking = {
        userId: doc.id,
        displayName: userData.nickname || 'Anonymous',
        score: Math.round(userData.brain_health?.brainHealthIndex || 0),
        rank: rank,
        countryCode: userData.country || 'unknown',
        brainHealthIndexLevel: userData.brain_health?.brainHealthIndexLevel || 1,
        isCurrentUser: context.auth && doc.id === context.auth.uid
      };

      if (ranking.isCurrentUser) {
        currentUserRank = ranking;
      }

      if (rank <= 10) { // 상위 10명만 포함
        rankings.push(ranking);
      }

      rank++;
    });

    // 현재 사용자가 상위 10위 안에 없다면 추가
    if (currentUserRank && !rankings.some(r => r.userId === currentUserRank.userId)) {
      rankings.push(currentUserRank);
    }

    return rankings;

  } catch (error) {
    console.error('Error getting user rankings:', error);
    throw new functions.https.HttpsError('internal', 'Error retrieving rankings');
  }
});

// 브레인 헬스 통계 조회
exports.getBrainHealthStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const userId = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User document not found');
    }

    const userData = userDoc.data();
    const brainHealth = userData.brain_health || {};

    return {
      brainHealthIndex: brainHealth.brainHealthIndex || 0,
      brainHealthIndexLevel: brainHealth.brainHealthIndexLevel || 1,
      totalGamesPlayed: brainHealth.totalGamesPlayed || 0,
      totalMatchesFound: brainHealth.totalMatchesFound || 0,
      bestTimesByGridSize: brainHealth.bestTimesByGridSize || {},
      bestTime: brainHealth.bestTime || 0,
      lastUpdated: brainHealth.lastUpdated,
      ageComponent: brainHealth.ageComponent || 0,
      activityComponent: brainHealth.activityComponent || 0,
      performanceComponent: brainHealth.performanceComponent || 0,
      persistenceBonus: brainHealth.persistenceBonus || 0,
      inactivityPenalty: brainHealth.inactivityPenalty || 0,
      daysSinceLastGame: brainHealth.daysSinceLastGame || 0
    };

  } catch (error) {
    console.error('Error getting brain health stats:', error);
    throw new functions.https.HttpsError('internal', 'Error retrieving brain health statistics');
  }
});

// 매일 자정에 실행되는 스케줄러 함수
exports.updateBrainHealthIndex = functions.pubsub
  .schedule('0 0 * * *') // 매일 자정에 실행
  .timeZone('Asia/Seoul') // 한국 시간대 기준
  .onRun(async (context) => {
    try {
      console.log('updateBrainHealthIndex scheduled function started');
      
      // 모든 사용자 문서 가져오기
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      console.log(`Processing ${usersSnapshot.size} users`);
      
      let updatedCount = 0;
      
      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        
        // brain_health 데이터가 있는지 확인
        if (userData.brain_health) {
          const brainHealthData = userData.brain_health;
          
          // 마지막 게임 시간 가져오기
          const lastGameTime = brainHealthData.lastUpdated?.toDate() || new Date(0);
          const now = new Date();
          const daysSinceLastGame = Math.floor((now - lastGameTime) / (1000 * 60 * 60 * 24));
          
          // 비활동 패널티 계산 (하루마다 2점씩 감소, 최대 20점)
          let inactivityPenalty = 0;
          if (daysSinceLastGame > 0) {
            inactivityPenalty = Math.min(daysSinceLastGame * 2, 20);
          }
          
          // 현재 brainHealthIndex 가져오기
          let currentIndex = brainHealthData.brainHealthIndex || 0;
          
          // 비활동 패널티 적용
          currentIndex = Math.max(0, currentIndex - inactivityPenalty);
          
          // brainHealthIndexLevel 계산
          let indexLevel;
          if (currentIndex < 35) {
            indexLevel = 1;
          } else if (currentIndex < 60) {
            indexLevel = 2;
          } else if (currentIndex < 80) {
            indexLevel = 3;
          } else if (currentIndex < 95) {
            indexLevel = 4;
          } else {
            indexLevel = 5;
          }
          
          // 사용자 문서 업데이트
          await userDoc.ref.update({
            'brain_health.brainHealthIndex': currentIndex,
            'brain_health.brainHealthIndexLevel': indexLevel,
            'brain_health.inactivityPenalty': inactivityPenalty,
            'brain_health.daysSinceLastGame': daysSinceLastGame,
            'brain_health.lastUpdated': admin.firestore.FieldValue.serverTimestamp()
          });
          
          updatedCount++;
          console.log(`Updated brain health index for user ${userDoc.id}: ${currentIndex}, level: ${indexLevel}`);
        }
      }
      
      console.log(`Successfully updated brain health indices for ${updatedCount} users`);
      return null;
    } catch (error) {
      console.error('Error updating brain health indices:', error);
      return null;
    }
  });

// 브레인 헬스 인덱스 업데이트 함수 테스트용 (HTTP 호출 가능)
exports.testUpdateBrainHealthIndex = functions.https.onCall(async (data, context) => {
  try {
    console.log('testUpdateBrainHealthIndex function started');
    
    // 모든 사용자 문서 가져오기
    const usersSnapshot = await admin.firestore().collection('users').get();
    
    console.log(`Processing ${usersSnapshot.size} users`);
    
    let updatedCount = 0;
    const results = [];
    
    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      
      // brain_health 데이터가 있는지 확인
      if (userData.brain_health) {
        const brainHealthData = userData.brain_health;
        
        // 마지막 게임 시간 가져오기
        const lastGameTime = brainHealthData.lastUpdated?.toDate() || new Date(0);
        const now = new Date();
        const daysSinceLastGame = Math.floor((now - lastGameTime) / (1000 * 60 * 60 * 24));
        
        // 비활동 패널티 계산 (하루마다 2점씩 감소, 최대 20점)
        let inactivityPenalty = 0;
        if (daysSinceLastGame > 0) {
          inactivityPenalty = Math.min(daysSinceLastGame * 2, 20);
        }
        
        // 현재 brainHealthIndex 가져오기
        let currentIndex = brainHealthData.brainHealthIndex || 0;
        
        // 비활동 패널티 적용
        currentIndex = Math.max(0, currentIndex - inactivityPenalty);
        
        // brainHealthIndexLevel 계산
        let indexLevel;
        if (currentIndex < 35) {
          indexLevel = 1;
        } else if (currentIndex < 60) {
          indexLevel = 2;
        } else if (currentIndex < 80) {
          indexLevel = 3;
        } else if (currentIndex < 95) {
          indexLevel = 4;
        } else {
          indexLevel = 5;
        }
        
        // 사용자 문서 업데이트
        await userDoc.ref.update({
          'brain_health.brainHealthIndex': currentIndex,
          'brain_health.brainHealthIndexLevel': indexLevel,
          'brain_health.inactivityPenalty': inactivityPenalty,
          'brain_health.daysSinceLastGame': daysSinceLastGame,
          'brain_health.lastUpdated': admin.firestore.FieldValue.serverTimestamp()
        });
        
        updatedCount++;
        const result = {
          userId: userDoc.id,
          brainHealthIndex: currentIndex,
          brainHealthIndexLevel: indexLevel,
          inactivityPenalty: inactivityPenalty,
          daysSinceLastGame: daysSinceLastGame
        };
        results.push(result);
        console.log(`Updated brain health index for user ${userDoc.id}: ${currentIndex}, level: ${indexLevel}`);
      }
    }
    
    console.log(`Successfully updated brain health indices for ${updatedCount} users`);
    return {
      success: true,
      updatedCount: updatedCount,
      results: results
    };
  } catch (error) {
    console.error('Error updating brain health indices:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

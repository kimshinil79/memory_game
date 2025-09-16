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

    // 점수 기록 업데이트
    const scoreHistory = brainHealth.scoreHistory || {};
    
    // 가장 최근의 타임스탬프 찾기
    let latestTimestamp = '0';
    let latestScore = 0;
    
    // 모든 타임스탬프 순회하여 가장 최근 것 찾기
    for (const key in scoreHistory) {
      if (key > latestTimestamp) {
        latestTimestamp = key;
        latestScore = scoreHistory[key];
      }
    }
    
    // 새 타임스탬프 생성
    const timestamp = Date.now().toString();
    
    // 최근 항목의 점수에 새 점수 더하기
    if (latestTimestamp !== '0') {
      console.log(`최근 항목 찾음: ${latestTimestamp}, 점수: ${latestScore}`);
      scoreHistory[timestamp] = latestScore + score;
      console.log(`새 항목 생성: ${timestamp}, 점수: ${latestScore + score} (${latestScore} + ${score})`);
    } else {
      // 이전 기록이 없는 경우 새 점수만 저장
    scoreHistory[timestamp] = score;
      console.log(`이전 기록 없음, 새 항목 생성: ${timestamp}, 점수: ${score}`);
    }

    // 브레인 헬스 인덱스 계산
    const brainHealthResult = await calculateBrainHealthIndex(userId, scoreHistory, totalGamesPlayed, totalMatchesFound, bestTimesByGridSize);

    // Firestore 업데이트
    await userRef.update({
      'brain_health': {
        brainHealthScore: score,
        brainHealthIndex: brainHealthResult.brainHealthIndex,
        brainHealthIndexLevel: brainHealthResult.indexLevel,
        totalGamesPlayed,
        totalMatchesFound,
        bestTimesByGridSize,
        bestTime: bestTime === Infinity ? 0 : bestTime,
        scoreHistory: scoreHistory,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        ageComponent: brainHealthResult.ageComponent,
        activityComponent: brainHealthResult.activityComponent,
        performanceComponent: brainHealthResult.performanceComponent,
        persistenceBonus: brainHealthResult.persistenceBonus,
        inactivityPenalty: brainHealthResult.inactivityPenalty,
        daysSinceLastGame: brainHealthResult.daysSinceLastGame,
        levelDropDueToInactivity: brainHealthResult.levelDropDueToInactivity,
        pointsToNextLevel: brainHealthResult.pointsToNextLevel
      }
    });

    return {
      success: true,
      brainHealthIndex: brainHealthResult.brainHealthIndex,
      brainHealthIndexLevel: brainHealthResult.indexLevel
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

// 15분마다 실행되는 스케줄러 함수 - Brain Health Index 업데이트
exports.updateBrainHealthIndex = functions.pubsub
  .schedule('*/15 * * * *') // 15분마다 실행
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
          
          // 점수 기록 가져오기
          const scoreHistory = brainHealthData.scoreHistory || {};
          const totalGamesPlayed = brainHealthData.totalGamesPlayed || 0;
          const totalMatchesFound = brainHealthData.totalMatchesFound || 0;
          const bestTimesByGridSize = brainHealthData.bestTimesByGridSize || {};
          
          // 브레인 헬스 인덱스 계산
          const brainHealthResult = await calculateBrainHealthIndex(
            userDoc.id, 
            scoreHistory, 
            totalGamesPlayed, 
            totalMatchesFound, 
            bestTimesByGridSize
          );
          
          // 사용자 문서 업데이트
          await userDoc.ref.update({
            'brain_health.brainHealthIndex': brainHealthResult.brainHealthIndex,
            'brain_health.brainHealthIndexLevel': brainHealthResult.indexLevel,
            'brain_health.ageComponent': brainHealthResult.ageComponent,
            'brain_health.activityComponent': brainHealthResult.activityComponent,
            'brain_health.performanceComponent': brainHealthResult.performanceComponent,
            'brain_health.persistenceBonus': brainHealthResult.persistenceBonus,
            'brain_health.inactivityPenalty': brainHealthResult.inactivityPenalty,
            'brain_health.daysSinceLastGame': brainHealthResult.daysSinceLastGame,
            'brain_health.levelDropDueToInactivity': brainHealthResult.levelDropDueToInactivity,
            'brain_health.pointsToNextLevel': brainHealthResult.pointsToNextLevel,
            'brain_health.lastBHIUpdate': admin.firestore.FieldValue.serverTimestamp()
          });
          
          updatedCount++;
          console.log(`Updated brain health index for user ${userDoc.id}: ${brainHealthResult.brainHealthIndex}, level: ${brainHealthResult.indexLevel}`);
        }
      }
      
      console.log(`Successfully updated brain health indices for ${updatedCount} users`);
      return null;
    } catch (error) {
      console.error('Error updating brain health indices:', error);
      return null;
    }
  });

// 브레인 헬스 인덱스 계산 함수
async function calculateBrainHealthIndex(userId, scoreHistory, totalGamesPlayed, totalMatchesFound, bestTimesByGridSize) {
  try {
    // 기본 지수 값 (60으로 설정)
    const baseIndex = 60.0;

    // 현재 날짜
    const now = new Date();

    // 사용자 나이 가져오기 (Firebase 사용자 정보에서)
    let userAge = 30; // 기본값 30

    try {
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        
        // 먼저 birthday 필드가 있는지 확인
        if (userData.birthday) {
          try {
            const birthDate = userData.birthday.toDate();
            userAge = Math.floor((now - birthDate) / (1000 * 60 * 60 * 24 * 365));
            
            // 계산된 나이가 비정상적으로 크거나 작을 경우 기본값 사용
            if (userAge < 0 || userAge > 120) {
              userAge = 30;
            }
          } catch (e) {
            console.error('Error calculating age from birthday:', e);
            // 오류 발생 시 age 필드 확인
            if (userData.age) {
              userAge = userData.age;
            }
          }
        } 
        // birthday가 없고 age 필드가 있는 경우
        else if (userData.age) {
          userAge = userData.age;
          // 값이 비정상적으로 크거나 작을 경우 기본값 사용
          if (userAge < 0 || userAge > 120) {
            userAge = 30;
          }
        }
      }
    } catch (e) {
      console.error('Error fetching user age from Firebase:', e);
    }

    // 나이 기반 조정 (35세 이상부터 점수 감소, 효과 증가)
    let ageAdjustment = 0;
    if (userAge > 35) {
      ageAdjustment = (userAge - 35) * 0.3; // 나이가 많을수록 지수 감소
      ageAdjustment = Math.min(ageAdjustment, 20); // 최대 감소량 20
    }

    // 지난 일주일간 게임 활동 평가
    let recentGames = 0;
    const recentGameDates = [];

    // 점수 기록에서 최근 활동 확인
    for (const timestamp in scoreHistory) {
      const date = new Date(parseInt(timestamp));
      const daysDifference = Math.floor((now - date) / (1000 * 60 * 60 * 24));
      
      if (daysDifference <= 7) {
        recentGames++;
        recentGameDates.push(date);
      }
    }

    // 최근 게임 활동 기반 조정 (보상 증가)
    let activityAdjustment = recentGames * 1.5; // 게임당 1.5점
    activityAdjustment = Math.min(activityAdjustment, 15); // 최대 15점

    // 연속 활동 부재에 대한 패널티 추가
    let inactivityPenalty = 0;
    let levelDropDueToInactivity = 0; // 비활동으로 인한 레벨 감소 추적

    // 최근 게임 날짜 정렬
    recentGameDates.sort((a, b) => b - a); // 최신 날짜가 앞으로 오도록 정렬

    // 마지막 게임 이후 지난 일수 계산
    let daysSinceLastGame = 0;
    if (recentGameDates.length > 0) {
      daysSinceLastGame = Math.floor((now - recentGameDates[0]) / (1000 * 60 * 60 * 24));
    } else {
      daysSinceLastGame = 7; // 최근 기록이 없으면 최대 패널티
    }

    // 비활동 패널티 계산 (하루만 안해도 패널티 적용)
    if (daysSinceLastGame > 0) {
      // 하루마다 2점씩 감소
      inactivityPenalty = daysSinceLastGame * 2.0;
      // 최대 패널티 제한
      inactivityPenalty = Math.min(inactivityPenalty, 20);

      // 하루라도 건너뛰면 레벨 감소 추적
      levelDropDueToInactivity = Math.min(daysSinceLastGame, 4); // 최대 4단계까지만 떨어지도록 제한
    }

    // 그리드 성능 평가
    let gridPerformance = 0;

    // 각 그리드 크기별 점수 계산 (난이도 증가)
    for (const gridSize in bestTimesByGridSize) {
      const bestTime = bestTimesByGridSize[gridSize];
      if (bestTime > 0) {
        // 그리드 크기에 따른 기대 시간 (초 단위) - 조금 더 엄격한 기준 적용
        let expectedTime;
        switch (gridSize) {
          case "2x2":
            expectedTime = 10; // 15에서 10으로 감소
            break;
          case "4x2":
          case "2x4":
            expectedTime = 25; // 30에서 25로 감소
            break;
          case "4x3":
          case "3x4":
            expectedTime = 50; // 60에서 50으로 감소
            break;
          case "4x4":
            expectedTime = 75; // 90에서 75로 감소
            break;
          case "5x4":
          case "4x5":
            expectedTime = 100; // 120에서 100으로 감소
            break;
          case "6x5":
          case "5x6":
            expectedTime = 150; // 180에서 150으로 감소
            break;
          default:
            expectedTime = 50;
        }

        // 기대 시간보다 빠를수록 더 높은 점수 (보상 감소)
        const timeFactor = Math.max(0.5, Math.min(expectedTime / bestTime, 1.8)); // 최대 보상 1.8
        gridPerformance += timeFactor * 1.5; // 가중치 1.5
      }
    }

    // 그리드 성능 점수 제한
    gridPerformance = Math.min(gridPerformance, 18); // 최대 18점

    // 플레이 횟수에 따른 보너스 (지속적인 플레이 필요)
    let persistenceBonus = 0;
    if (totalGamesPlayed >= 5) persistenceBonus = 2;
    if (totalGamesPlayed >= 10) persistenceBonus = 4;
    if (totalGamesPlayed >= 20) persistenceBonus = 7;
    if (totalGamesPlayed >= 50) persistenceBonus = 10;
    if (totalGamesPlayed >= 100) persistenceBonus = 15;

    // 최종 지수 계산 (로그 함수 적용으로 상위 점수대 진입 어렵게)
    let rawIndex = baseIndex -
        ageAdjustment +
        activityAdjustment +
        gridPerformance +
        persistenceBonus -
        inactivityPenalty; // 비활동 패널티 적용

    // 로그 함수를 사용해 높은 점수대에서 진행이 느려지도록 조정
    // 85점 이상부터 점수 획득이 급격히 어려워짐
    let finalIndex = rawIndex;
    if (rawIndex > 85) {
      const excess = rawIndex - 85;
      const logFactor = 1 + (0.5 * (1 - (1 / (1 + 0.1 * excess)))); // 로그 기반 감쇠 함수
      finalIndex = 85 + (excess / logFactor);
    }

    finalIndex = Math.max(0, Math.min(finalIndex, 100));

    // 지수 레벨 계산 (1-5) - 상위 레벨 기준 상향
    let indexLevel;
    if (finalIndex < 35) {
      indexLevel = 1;
    } else if (finalIndex < 60) {
      indexLevel = 2;
    } else if (finalIndex < 80) {
      indexLevel = 3;
    } else if (finalIndex < 95) {
      indexLevel = 4;
    } else {
      indexLevel = 5;
    }

    // 비활동으로 인한 레벨 감소 적용
    indexLevel = Math.max(1, Math.min(indexLevel - levelDropDueToInactivity, 5));

    // 다음 레벨까지 필요한 포인트 계산
    let pointsToNext = 0;
    if (indexLevel < 5) {
      const thresholds = [0, 35, 60, 80, 95, 100]; // 기준 업데이트
      pointsToNext = thresholds[indexLevel] - finalIndex;
      pointsToNext = Math.ceil(Math.abs(pointsToNext));
    }

    return {
      brainHealthIndex: finalIndex,
      indexLevel: indexLevel,
      pointsToNextLevel: pointsToNext,
      ageComponent: ageAdjustment,
      activityComponent: activityAdjustment,
      performanceComponent: gridPerformance,
      persistenceBonus: persistenceBonus,
      inactivityPenalty: inactivityPenalty,
      daysSinceLastGame: daysSinceLastGame,
      levelDropDueToInactivity: levelDropDueToInactivity,
      details: {
        age: userAge,
        recentGames: recentGames,
        totalGames: totalGamesPlayed,
      }
    };
  } catch (e) {
    console.error('Error calculating brain health index:', e);
    return {
      brainHealthIndex: 0,
      indexLevel: 1,
      pointsToNextLevel: 0,
      ageComponent: 0,
      activityComponent: 0,
      performanceComponent: 0,
      persistenceBonus: 0,
      inactivityPenalty: 0,
      daysSinceLastGame: 7,
      levelDropDueToInactivity: 0,
      details: {
        age: 30,
        recentGames: 0,
        totalGames: 0
      }
    };
  }
}

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
        
        // 점수 기록 가져오기
        const scoreHistory = brainHealthData.scoreHistory || {};
        const totalGamesPlayed = brainHealthData.totalGamesPlayed || 0;
        const totalMatchesFound = brainHealthData.totalMatchesFound || 0;
        const bestTimesByGridSize = brainHealthData.bestTimesByGridSize || {};
        
        // 브레인 헬스 인덱스 계산
        const brainHealthResult = await calculateBrainHealthIndex(
          userDoc.id, 
          scoreHistory, 
          totalGamesPlayed, 
          totalMatchesFound, 
          bestTimesByGridSize
        );
        
        // 사용자 문서 업데이트
        await userDoc.ref.update({
          'brain_health.brainHealthIndex': brainHealthResult.brainHealthIndex,
          'brain_health.brainHealthIndexLevel': brainHealthResult.indexLevel,
          'brain_health.ageComponent': brainHealthResult.ageComponent,
          'brain_health.activityComponent': brainHealthResult.activityComponent,
          'brain_health.performanceComponent': brainHealthResult.performanceComponent,
          'brain_health.persistenceBonus': brainHealthResult.persistenceBonus,
          'brain_health.inactivityPenalty': brainHealthResult.inactivityPenalty,
          'brain_health.daysSinceLastGame': brainHealthResult.daysSinceLastGame,
          'brain_health.levelDropDueToInactivity': brainHealthResult.levelDropDueToInactivity,
          'brain_health.pointsToNextLevel': brainHealthResult.pointsToNextLevel,
          'brain_health.lastBHIUpdate': admin.firestore.FieldValue.serverTimestamp()
        });
        
        updatedCount++;
        const result = {
          userId: userDoc.id,
          brainHealthIndex: brainHealthResult.brainHealthIndex,
          brainHealthIndexLevel: brainHealthResult.indexLevel,
          ageComponent: brainHealthResult.ageComponent,
          activityComponent: brainHealthResult.activityComponent,
          performanceComponent: brainHealthResult.performanceComponent,
          persistenceBonus: brainHealthResult.persistenceBonus,
          inactivityPenalty: brainHealthResult.inactivityPenalty,
          daysSinceLastGame: brainHealthResult.daysSinceLastGame
        };
        results.push(result);
        console.log(`Updated brain health index for user ${userDoc.id}: ${brainHealthResult.brainHealthIndex}, level: ${brainHealthResult.indexLevel}`);
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

// 멀티플레이어 게임 승자 점수 업데이트 함수
exports.updateMultiplayerGameWinnerScore = functions.https.onCall(async (data, context) => {
  console.log('========== 멀티플레이어 게임 승자 점수 업데이트 함수 시작 ==========');
  console.log('수신한 데이터:', JSON.stringify(data));
  console.log('호출 컨텍스트:', context.auth ? `인증됨 (${context.auth.uid})` : '인증되지 않음');
  
  // 인증 확인
  if (!context.auth) {
    console.error('인증 오류: 사용자가 인증되지 않았습니다');
    throw new functions.https.HttpsError('unauthenticated', '사용자 인증이 필요합니다');
  }

  try {
    const { winnerId, score, gridSize, matchCount, timeSpent } = data;
    
    console.log(`승자 ID: ${winnerId}`);
    console.log(`점수: ${score}`);
    console.log(`그리드 크기: ${gridSize}`);
    console.log(`매치 수: ${matchCount}`);
    console.log(`소요 시간: ${timeSpent}초`);
    
    if (!winnerId) {
      console.error('유효성 검사 오류: 승자 ID가 제공되지 않았습니다');
      throw new functions.https.HttpsError('invalid-argument', '승자 ID가 필요합니다');
    }
    
    if (typeof score !== 'number' || score <= 0) {
      console.error(`유효성 검사 오류: 유효하지 않은 점수 값 (${score})`);
      throw new functions.https.HttpsError('invalid-argument', '유효한 점수가 필요합니다');
    }

    console.log(`멀티플레이어 게임 승자 점수 업데이트: 사용자 ID=${winnerId}, 점수=${score}`);

    // Firestore에서 사용자 문서 가져오기
    console.log(`사용자 문서 가져오기: users/${winnerId}`);
    const userDoc = await admin.firestore().collection('users').doc(winnerId).get();
    
    if (!userDoc.exists) {
      console.error(`오류: 사용자 문서를 찾을 수 없음 (ID: ${winnerId})`);
      throw new functions.https.HttpsError('not-found', '사용자 문서를 찾을 수 없습니다');
    }

    console.log(`사용자 문서 가져옴: ${userDoc.id}`);
    const userData = userDoc.data();
    let brainHealth = userData.brain_health || {};
    
    // 현재 Brain Health 점수
    const currentScore = brainHealth.brainHealthScore || 0;
    const newScore = currentScore + score;
    console.log(`현재 점수: ${currentScore}, 새 점수: ${newScore} (+${score})`);
    
    // 게임 통계 업데이트
    const totalGamesPlayed = (brainHealth.totalGamesPlayed || 0) + 1;
    const totalMatchesFound = (brainHealth.totalMatchesFound || 0) + (matchCount || 0);
    console.log(`총 게임 수: ${totalGamesPlayed}, 총 매치 수: ${totalMatchesFound}`);
    
    // 최고 기록 업데이트 (gridSize가 제공된 경우)
    const bestTimesByGridSize = brainHealth.bestTimesByGridSize || {};
    if (gridSize && timeSpent) {
      const previousBestTime = bestTimesByGridSize[gridSize] || Infinity;
      if (!bestTimesByGridSize[gridSize] || timeSpent < bestTimesByGridSize[gridSize]) {
        bestTimesByGridSize[gridSize] = timeSpent;
        console.log(`${gridSize} 최고 기록 업데이트: ${previousBestTime} → ${timeSpent}`);
      } else {
        console.log(`${gridSize} 최고 기록 유지: ${previousBestTime}`);
      }
    }

    // 점수 기록 업데이트
    const scoreHistory = brainHealth.scoreHistory || {};
    
    // 가장 최근의 타임스탬프 찾기
    let latestTimestamp = '0';
    let latestScore = 0;
    
    // 모든 타임스탬프 순회하여 가장 최근 것 찾기
    for (const key in scoreHistory) {
      if (key > latestTimestamp) {
        latestTimestamp = key;
        latestScore = scoreHistory[key];
      }
    }
    
    // 새 타임스탬프 생성
    const timestamp = Date.now().toString();
    
    // 최근 항목의 점수에 새 점수 더하기
    if (latestTimestamp !== '0') {
      console.log(`최근 항목 찾음: ${latestTimestamp}, 점수: ${latestScore}`);
      scoreHistory[timestamp] = latestScore + score;
      console.log(`새 항목 생성: ${timestamp}, 점수: ${latestScore + score} (${latestScore} + ${score})`);
    } else {
      // 이전 기록이 없는 경우 새 점수만 저장
    scoreHistory[timestamp] = score;
      console.log(`이전 기록 없음, 새 항목 생성: ${timestamp}, 점수: ${score}`);
    }
    
    // Brain Health Index 계산
    console.log('Brain Health Index 계산 시작...');
    const brainHealthResult = await calculateBrainHealthIndex(
      winnerId, 
      scoreHistory, 
      totalGamesPlayed, 
      totalMatchesFound, 
      bestTimesByGridSize
    );
    console.log(`계산된 Brain Health Index: ${brainHealthResult.brainHealthIndex}, 레벨: ${brainHealthResult.indexLevel}`);

    // Firestore 업데이트
    console.log(`Firestore 업데이트 시작: users/${winnerId}`);
    await admin.firestore().collection('users').doc(winnerId).update({
      'brain_health.brainHealthScore': newScore,
      'brain_health.brainHealthIndex': brainHealthResult.brainHealthIndex,
      'brain_health.brainHealthIndexLevel': brainHealthResult.indexLevel,
      'brain_health.totalGamesPlayed': totalGamesPlayed,
      'brain_health.totalMatchesFound': totalMatchesFound,
      'brain_health.bestTimesByGridSize': bestTimesByGridSize,
      'brain_health.scoreHistory': scoreHistory,
      'brain_health.lastUpdated': admin.firestore.FieldValue.serverTimestamp(),
      'brain_health.ageComponent': brainHealthResult.ageComponent,
      'brain_health.activityComponent': brainHealthResult.activityComponent,
      'brain_health.performanceComponent': brainHealthResult.performanceComponent,
      'brain_health.persistenceBonus': brainHealthResult.persistenceBonus,
      'brain_health.inactivityPenalty': brainHealthResult.inactivityPenalty,
      'brain_health.daysSinceLastGame': brainHealthResult.daysSinceLastGame,
      'brain_health.pointsToNextLevel': brainHealthResult.pointsToNextLevel
    });
    console.log(`Firestore 업데이트 완료: users/${winnerId}`);

    console.log(`사용자 ${winnerId}의 점수가 ${currentScore}에서 ${newScore}로 업데이트되었습니다`);
    console.log('========== 멀티플레이어 게임 승자 점수 업데이트 함수 완료 ==========');

    return {
      success: true,
      previousScore: currentScore,
      newScore: newScore,
      addedPoints: score,
      brainHealthIndex: brainHealthResult.brainHealthIndex,
      brainHealthIndexLevel: brainHealthResult.indexLevel
    };

  } catch (error) {
    console.error('멀티플레이어 게임 승자 점수 업데이트 오류:', error);
    console.log('========== 멀티플레이어 게임 승자 점수 업데이트 함수 오류로 종료 ==========');
    throw new functions.https.HttpsError('internal', '점수 업데이트 중 오류가 발생했습니다: ' + error.message);
  }
});

// Helper function to get brain level from score
function getBrainLevelFromScore(score) {
    if (score >= 1000) return 5;
    if (score >= 800) return 4;
    if (score >= 600) return 3;
    if (score >= 400) return 2;
    return 1;
}
  
// Helper function to get points needed for next level
function getPointsToNextLevelFromScore(score) {
    if (score >= 1000) return 0; // Max level
    if (score >= 800) return 1000 - score;
    if (score >= 600) return 800 - score;
    if (score >= 400) return 600 - score;
    return 400 - score;
}

// Scheduled function to send daily brain health notifications
exports.sendDailyBrainNotifications = functions.pubsub
    .schedule("every day 20:00")
    .timeZone('Asia/Seoul')
    .onRun(async (context) => {
        console.log("Executing daily brain notification function.");

        const usersSnapshot = await admin.firestore().collection("users").get();

        if (usersSnapshot.empty) {
            console.log("No users found. Exiting function.");
            return null;
        }

        const today = new Date();
        const yesterday = new Date();
        yesterday.setDate(today.getDate() - 1);

        const todayStr = today.toISOString().split("T")[0]; // YYYY-MM-DD
        const yesterdayStr = yesterday.toISOString().split("T")[0]; // YYYY-MM-DD

        const promises = [];

        usersSnapshot.forEach((doc) => {
            const user = doc.data();

            if (!user.fcmToken) {
                console.log(`User ${doc.id} has no FCM token. Skipping.`);
                return;
            }

            const brainHealth = user.brain_health;
            if (!brainHealth) {
                console.log(`User ${doc.id} has no brain health data. Skipping.`);
                return;
            }

            const currentScore = brainHealth.brainHealthScore ?? 0;
            const scoreHistory = brainHealth.scoreHistory || {};
            const yesterdayScore = scoreHistory[yesterdayStr] ?? currentScore;

            const currentLevel = getBrainLevelFromScore(currentScore);
            const yesterdayLevel = getBrainLevelFromScore(yesterdayScore);

            let title = "";
            let body = "";

            if (currentLevel < yesterdayLevel) {
                title = "Let's Boost Your Brain! 💪";
                body = `Your brain level was ${yesterdayLevel} yesterday, but it's ${currentLevel} today. Let's play a game to level up!`;
            } else {
                const pointsToNext = getPointsToNextLevelFromScore(currentScore);
                if (pointsToNext > 0) {
                    title = "You're So Close! ✨";
                    body = `You are only ${pointsToNext} points away from Level ${currentLevel + 1}. You can do it!`;
                } else {
                    title = "Amazing Brain! 🧠🏆";
                    body = "You've reached the highest brain level! Keep playing to maintain your sharp mind.";
                }
            }

            if (title && body) {
                const message = {
                    token: user.fcmToken,
                    notification: { title, body },
                    data: { screen: "brain_health_page" },
                };
                promises.push(admin.messaging().send(message));
            }
            
            // Update score history for today if it doesn't exist
            if (!scoreHistory[todayStr]) {
                const scoreHistoryUpdate = {
                    ...scoreHistory,
                    [todayStr]: currentScore
                };
                const update = { "brain_health.scoreHistory": scoreHistoryUpdate };
                promises.push(doc.ref.update(update));
            }
        });

        try {
            await Promise.all(promises);
            console.log("Successfully processed all users for daily notifications.");
        } catch (error) {
            console.error("Error processing user notifications:", error);
        }

        return null;
    });

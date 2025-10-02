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

// Safe server timestamp helper (works on emulator and production)
function getServerTimestamp() {
  try {
    const fv = admin.firestore && admin.firestore.FieldValue;
    if (fv && typeof fv.serverTimestamp === 'function') {
      return fv.serverTimestamp();
    }
  } catch (_) {}
  return admin.firestore.Timestamp.now();
}

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
        lastUpdated: getServerTimestamp(),
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

// 2시간마다 실행되는 스케줄러 함수 - Brain Health Index 업데이트
exports.updateBrainHealthIndex = functions.pubsub
  .schedule('0 */2 * * *') // 2시간마다 실행 (매 2시간의 0분에 실행)
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
    // 기본 지수값을 낮춰 전체 레벨을 보수적으로 조정
    const baseIndex = 50.0;

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

    // 지난 일주일간 게임 활동 평가 (활동 빈도에 큰 가중치)
    let recentGames = 0;
    const recentGameDates = [];

    // 점수 기록에서 최근 활동 확인
    for (const timestamp in scoreHistory) {
      let date;
      
      // timestamp가 숫자인지 날짜 문자열인지 확인
      if (!isNaN(timestamp) && timestamp.length > 10) {
        // 숫자 형식의 timestamp (밀리초)
        date = new Date(parseInt(timestamp));
      } else if (timestamp.includes('-')) {
        // 날짜 문자열 형식 (YYYY-MM-DD)
        date = new Date(timestamp);
      } else {
        // 기타 형식은 건너뜀
        console.log(`Invalid timestamp format: ${timestamp}`);
        continue;
      }
      
      // 유효한 날짜인지 확인
      if (isNaN(date.getTime())) {
        console.log(`Invalid date from timestamp: ${timestamp}`);
        continue;
      }
      
      const daysDifference = Math.floor((now - date) / (1000 * 60 * 60 * 24));
      
      if (daysDifference <= 7) {
        recentGames++;
        recentGameDates.push(date);
      }
    }

    // 최근 게임 날짜 정렬
    recentGameDates.sort((a, b) => b - a); // 최신 날짜가 앞으로 오도록 정렬

    // 마지막 게임 이후 지난 일수 계산
    let daysSinceLastGame = 0;
    if (recentGameDates.length > 0) {
      daysSinceLastGame = Math.floor((now - recentGameDates[0]) / (1000 * 60 * 60 * 24));
    } else {
      daysSinceLastGame = 999; // 최근 기록이 없으면 매우 오래된 것으로 간주
    }

    // ⭐ 3일 이상 안하면 무조건 똥뇌(레벨 1)로 강제 설정
    if (daysSinceLastGame > 3) {
      console.log(`User has been inactive for ${daysSinceLastGame} days - forcing level 1`);
      return {
        brainHealthIndex: 20.0, // 똥뇌 레벨에 해당하는 낮은 점수
        indexLevel: 1,
        pointsToNextLevel: 10, // 레벨 2까지 10점 필요
        ageComponent: ageAdjustment,
        activityComponent: 0,
        performanceComponent: 0,
        persistenceBonus: 0,
        inactivityPenalty: 999, // 최대 패널티 표시
        daysSinceLastGame: daysSinceLastGame,
        levelDropDueToInactivity: 5, // 모든 레벨 상실
        details: {
          age: userAge,
          recentGames: recentGames,
          totalGames: totalGamesPlayed,
          reason: 'Inactive for more than 3 days'
        }
      };
    }

    // 활동 빈도에 큰 가중치 부여 (게임당 3.0점, 최대 25점)
    let activityAdjustment = recentGames * 3.0;
    activityAdjustment = Math.min(activityAdjustment, 25);

    // 비활동 패널티 (3일 이내에도 활동 빈도가 적으면 패널티)
    let inactivityPenalty = 0;
    let levelDropDueToInactivity = 0;
    
    // 최근 3일간 게임 횟수 체크
    const gamesInLast3Days = recentGameDates.filter(date => {
      const daysDiff = Math.floor((now - date) / (1000 * 60 * 60 * 24));
      return daysDiff <= 3;
    }).length;
    
    // 3일간 게임이 2번 미만이면 패널티
    if (gamesInLast3Days < 2) {
      inactivityPenalty = 5; // 활동 부족 패널티
      levelDropDueToInactivity = 1;
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

        // 기대 시간보다 빠를수록 더 높은 점수 (보상 대폭 감소)
        const timeFactor = Math.max(0.5, Math.min(expectedTime / bestTime, 1.5)); // 최대 보상 1.5
        gridPerformance += timeFactor * 0.8; // 가중치 0.8 (활동 빈도보다 낮게)
      }
    }

    // 그리드 성능 점수 제한
    // 성능 보상 상한 대폭 하향: 최대 8점 (활동 빈도가 더 중요)
    gridPerformance = Math.min(gridPerformance, 8);

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

    // 로그 함수를 사용해 높은 점수대에서 진행이 느려지도록 조정 (완화됨)
    // 90점 이상부터 점수 획득이 조금씩 어려워짐 (85점에서 90점으로 상향)
    let finalIndex = rawIndex;
    if (rawIndex > 90) {
      const excess = rawIndex - 90;
      const logFactor = 1 + (0.3 * (1 - (1 / (1 + 0.15 * excess)))); // 감쇠 효과 완화 (0.5→0.3, 0.1→0.15)
      finalIndex = 90 + (excess / logFactor);
    }

    finalIndex = Math.max(0, Math.min(finalIndex, 100));

    // 지수 레벨 계산 (1-5) - 무지개 등급 달성 가능하도록 조정
    let indexLevel;
    // 레벨 기준을 상향 조정 (더 엄격)
    if (finalIndex < 30) {
      indexLevel = 1;
    } else if (finalIndex < 55) {
      indexLevel = 2;
    } else if (finalIndex < 78) {
      indexLevel = 3;
    } else if (finalIndex < 94) {
      indexLevel = 4;
    } else {
      indexLevel = 5; // 92점 이상이면 무지개 등급!
    }

    // 비활동으로 인한 레벨 감소 적용
    indexLevel = Math.max(1, Math.min(indexLevel - levelDropDueToInactivity, 5));

    // 다음 레벨까지 필요한 포인트 계산
    let pointsToNext = 0;
    if (indexLevel < 5) {
      // 상향된 임계값에 맞춰 다음 레벨까지 점수 계산
      const thresholds = [0, 30, 55, 78, 94, 100];
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
      'brain_health.lastUpdated': getServerTimestamp(),
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

// Multi-language notification messages
const notificationMessages = {
    // English (default)
    en: {
        levelDown: {
            title: "Let's Boost Your Brain! 💪",
            body: "Your brain level was {yesterdayLevel} yesterday, but it's {currentLevel} today. Let's play a game to level up!"
        },
        levelUp: {
            title: "You're So Close! ✨",
            body: "You are only {pointsToNext} points away from Level {nextLevel}. You can do it!"
        },
        maxLevel: {
            title: "Amazing Brain! 🧠🏆",
            body: "You've reached the highest brain level! Keep playing to maintain your sharp mind."
        }
    },
    // Korean
    ko: {
        levelDown: {
            title: "뇌 건강을 향상시켜요! 💪",
            body: "어제 뇌 레벨이 {yesterdayLevel}이었는데 오늘은 {currentLevel}이에요. 게임을 해서 레벨을 올려보세요!"
        },
        levelUp: {
            title: "조금만 더! ✨",
            body: "레벨 {nextLevel}까지 {pointsToNext}점만 더 필요해요. 할 수 있어요!"
        },
        maxLevel: {
            title: "놀라운 두뇌! 🧠🏆",
            body: "최고 뇌 레벨에 도달했어요! 계속 플레이해서 날카로운 두뇌를 유지하세요."
        }
    },
    // Japanese
    ja: {
        levelDown: {
            title: "脳を鍛えましょう！ 💪",
            body: "昨日の脳レベルは{yesterdayLevel}でしたが、今日は{currentLevel}です。ゲームをしてレベルアップしましょう！"
        },
        levelUp: {
            title: "もう少しです！ ✨",
            body: "レベル{nextLevel}まであと{pointsToNext}ポイントです。頑張って！"
        },
        maxLevel: {
            title: "素晴らしい頭脳！ 🧠🏆",
            body: "最高の脳レベルに到達しました！鋭い頭脳を維持するために続けてプレイしてください。"
        }
    },
    // Chinese Simplified
    zh: {
        levelDown: {
            title: "提升你的大脑！ 💪",
            body: "你昨天的大脑等级是{yesterdayLevel}，但今天是{currentLevel}。让我们玩游戏来升级吧！"
        },
        levelUp: {
            title: "你很接近了！ ✨",
            body: "你距离{nextLevel}级只差{pointsToNext}分了。你可以做到的！"
        },
        maxLevel: {
            title: "惊人的大脑！ 🧠🏆",
            body: "你已经达到了最高的大脑等级！继续游戏来保持你敏锐的头脑。"
        }
    },
    // Spanish
    es: {
        levelDown: {
            title: "¡Mejoremos tu cerebro! 💪",
            body: "Tu nivel cerebral era {yesterdayLevel} ayer, pero hoy es {currentLevel}. ¡Juguemos para subir de nivel!"
        },
        levelUp: {
            title: "¡Estás muy cerca! ✨",
            body: "Solo te faltan {pointsToNext} puntos para llegar al Nivel {nextLevel}. ¡Tú puedes!"
        },
        maxLevel: {
            title: "¡Cerebro increíble! 🧠🏆",
            body: "¡Has alcanzado el nivel cerebral más alto! Sigue jugando para mantener tu mente aguda."
        }
    },
    // French
    fr: {
        levelDown: {
            title: "Boostons votre cerveau ! 💪",
            body: "Votre niveau cérébral était {yesterdayLevel} hier, mais c'est {currentLevel} aujourd'hui. Jouons pour monter de niveau !"
        },
        levelUp: {
            title: "Vous êtes si proche ! ✨",
            body: "Il ne vous manque que {pointsToNext} points pour atteindre le Niveau {nextLevel}. Vous pouvez le faire !"
        },
        maxLevel: {
            title: "Cerveau incroyable ! 🧠🏆",
            body: "Vous avez atteint le plus haut niveau cérébral ! Continuez à jouer pour maintenir votre esprit vif."
        }
    },
    // German
    de: {
        levelDown: {
            title: "Lass uns dein Gehirn stärken! 💪",
            body: "Dein Gehirnlevel war gestern {yesterdayLevel}, aber heute ist es {currentLevel}. Lass uns ein Spiel spielen, um aufzusteigen!"
        },
        levelUp: {
            title: "Du bist so nah dran! ✨",
            body: "Du brauchst nur noch {pointsToNext} Punkte bis Level {nextLevel}. Du schaffst das!"
        },
        maxLevel: {
            title: "Erstaunliches Gehirn! 🧠🏆",
            body: "Du hast das höchste Gehirnlevel erreicht! Spiele weiter, um deinen scharfen Verstand zu erhalten."
        }
    },
    // Portuguese
    pt: {
        levelDown: {
            title: "Vamos impulsionar seu cérebro! 💪",
            body: "Seu nível cerebral era {yesterdayLevel} ontem, mas hoje é {currentLevel}. Vamos jogar para subir de nível!"
        },
        levelUp: {
            title: "Você está tão perto! ✨",
            body: "Você está apenas a {pointsToNext} pontos do Nível {nextLevel}. Você consegue!"
        },
        maxLevel: {
            title: "Cérebro incrível! 🧠🏆",
            body: "Você alcançou o nível cerebral mais alto! Continue jogando para manter sua mente afiada."
        }
    },
    // Arabic
    ar: {
        levelDown: {
            title: "لنعزز دماغك! 💪",
            body: "كان مستوى دماغك {yesterdayLevel} أمس، لكنه {currentLevel} اليوم. دعنا نلعب لنرتقي بالمستوى!"
        },
        levelUp: {
            title: "أنت قريب جداً! ✨",
            body: "أنت تحتاج فقط {pointsToNext} نقطة للوصول إلى المستوى {nextLevel}. يمكنك فعل ذلك!"
        },
        maxLevel: {
            title: "دماغ مذهل! 🧠🏆",
            body: "لقد وصلت إلى أعلى مستوى دماغي! استمر في اللعب للحفاظ على ذهنك الحاد."
        }
    },
    // Russian
    ru: {
        levelDown: {
            title: "Давайте улучшим ваш мозг! 💪",
            body: "Вчера ваш уровень мозга был {yesterdayLevel}, а сегодня {currentLevel}. Давайте играть, чтобы повысить уровень!"
        },
        levelUp: {
            title: "Вы так близко! ✨",
            body: "Вам нужно всего {pointsToNext} очков до Уровня {nextLevel}. Вы можете это сделать!"
        },
        maxLevel: {
            title: "Удивительный мозг! 🧠🏆",
            body: "Вы достигли высшего уровня мозга! Продолжайте играть, чтобы поддерживать острый ум."
        }
    }
};

// Function to get language code from country code
function getLanguageFromCountry(countryCode) {
    const countryToLanguage = {
        // Korean speaking countries
        'kr': 'ko', 'kp': 'ko',
        
        // Japanese speaking countries
        'jp': 'ja',
        
        // Chinese speaking countries
        'cn': 'zh', 'tw': 'zh', 'hk': 'zh', 'mo': 'zh', 'sg': 'zh',
        
        // Spanish speaking countries
        'es': 'es', 'mx': 'es', 'ar': 'es', 'co': 'es', 've': 'es', 'pe': 'es',
        'cl': 'es', 'ec': 'es', 'bo': 'es', 'py': 'es', 'uy': 'es', 'gw': 'es',
        'cu': 'es', 'do': 'es', 'pa': 'es', 'cr': 'es', 'sv': 'es', 'gt': 'es',
        'hn': 'es', 'ni': 'es', 'pr': 'es',
        
        // French speaking countries
        'fr': 'fr', 'be': 'fr', 'ch': 'fr', 'ca': 'fr', 'lu': 'fr', 'mc': 'fr',
        'sn': 'fr', 'ml': 'fr', 'bf': 'fr', 'ne': 'fr', 'ci': 'fr', 'gn': 'fr',
        'td': 'fr', 'cf': 'fr', 'cg': 'fr', 'ga': 'fr', 'cm': 'fr', 'dj': 'fr',
        'mg': 'fr', 'km': 'fr', 'sc': 'fr', 'vu': 'fr',
        
        // German speaking countries
        'de': 'de', 'at': 'de', 'li': 'de',
        
        // Portuguese speaking countries
        'pt': 'pt', 'br': 'pt', 'ao': 'pt', 'mz': 'pt', 'gw': 'pt', 'cv': 'pt',
        'st': 'pt', 'tl': 'pt',
        
        // Arabic speaking countries
        'sa': 'ar', 'ae': 'ar', 'qa': 'ar', 'kw': 'ar', 'bh': 'ar', 'om': 'ar',
        'jo': 'ar', 'lb': 'ar', 'sy': 'ar', 'iq': 'ar', 'ye': 'ar', 'eg': 'ar',
        'ly': 'ar', 'tn': 'ar', 'dz': 'ar', 'ma': 'ar', 'sd': 'ar', 'so': 'ar',
        'dj': 'ar', 'km': 'ar', 'td': 'ar', 'mr': 'ar',
        
        // Russian speaking countries
        'ru': 'ru', 'by': 'ru', 'kz': 'ru', 'kg': 'ru', 'tj': 'ru', 'uz': 'ru',
        'tm': 'ru', 'am': 'ru', 'az': 'ru', 'ge': 'ru', 'md': 'ru'
    };
    
    return countryToLanguage[countryCode?.toLowerCase()] || 'en';
}

// Function to format message with variables
function formatMessage(template, variables) {
    let formatted = template;
    for (const [key, value] of Object.entries(variables)) {
        formatted = formatted.replace(new RegExp(`{${key}}`, 'g'), value);
    }
    return formatted;
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

            // Get user's language based on country
            const userCountry = user.country || 'us';
            const userLanguage = getLanguageFromCountry(userCountry);
            const messages = notificationMessages[userLanguage] || notificationMessages.en;

            console.log(`User ${doc.id}: Country=${userCountry}, Language=${userLanguage}`);

            let title = "";
            let body = "";

            if (currentLevel < yesterdayLevel) {
                // Level decreased
                const template = messages.levelDown;
                title = template.title;
                body = formatMessage(template.body, {
                    yesterdayLevel: yesterdayLevel,
                    currentLevel: currentLevel
                });
            } else {
                const pointsToNext = getPointsToNextLevelFromScore(currentScore);
                if (pointsToNext > 0) {
                    // Close to next level
                    const template = messages.levelUp;
                    title = template.title;
                    body = formatMessage(template.body, {
                        pointsToNext: pointsToNext,
                        nextLevel: currentLevel + 1
                    });
                } else {
                    // Max level reached
                    const template = messages.maxLevel;
                    title = template.title;
                    body = template.body;
                }
            }

            if (title && body) {
                const message = {
                    token: user.fcmToken,
                    notification: { title, body },
                    data: { 
                        screen: "brain_health_page",
                        language: userLanguage 
                    },
                };
                promises.push(admin.messaging().send(message));
                console.log(`Sending notification to ${doc.id} in ${userLanguage}: ${title}`);
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

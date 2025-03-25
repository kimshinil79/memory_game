const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

// 'users/{userId}/notifications' 컬렉션에 문서가 추가될 때 실행되는 함수
exports.sendNotificationOnCreate = onDocumentCreated({
  document: 'users/{userId}/notifications/{notificationId}',
  region: 'us-central1'
}, async (event) => {
  try {
    const snapshot = event.data;
    if (!snapshot) {
      console.log('No data associated with the event');
      return null;
    }
    
    const notificationData = snapshot.data();
    
    // 알림 타입 확인 (challenge 타입만 처리)
    if (notificationData.type !== 'challenge') {
      console.log('Notification is not of type challenge, skipping:', notificationData);
      return null;
    }
    
    // 상대방의 FCM 토큰 확인
    if (!notificationData.recipientFcmToken) {
      console.log('Recipient FCM token missing. Notification data:', JSON.stringify(notificationData));
      return null;
    }
    
    // 토큰이 유효한지 검증 (최소 길이 등)
    if (typeof notificationData.recipientFcmToken !== 'string' || notificationData.recipientFcmToken.length < 10) {
      console.log('Invalid FCM token format:', notificationData.recipientFcmToken);
      return null;
    }

    console.log('Valid FCM token found (first 10 chars):', notificationData.recipientFcmToken.substring(0, 10) + "...");

    // 도전자 닉네임 확인
    const senderNickname = notificationData.senderNickname || '상대방';

    // FCM 메시지 구성
    const message = {
      token: notificationData.recipientFcmToken,
      notification: {
        title: '새로운 도전 요청',
        body: `${senderNickname}님이 메모리 게임 도전장을 보냈습니다!`,
      },
      data: {
        type: 'challenge',
        challengeId: snapshot.id,
        senderId: notificationData.senderId || '',
        senderNickname: notificationData.senderNickname || '상대방',
        gridSize: notificationData.gridSize || '',
        // 추가 데이터가 있다면 포함
      },
      android: {
        notification: {
          channelId: 'game_challenges',
          priority: 'high',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // 메시지 전송
    const response = await admin.messaging().send(message);
    console.log('Successfully sent notification:', response);
    
    // 전송 상태 업데이트
    await snapshot.ref.update({
      'notificationSent': true,
      'notificationSentAt': admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    return { error: error.message };
  }
});

// fcm_notifications 컬렉션에 문서가 추가될 때 실행되는 함수
exports.sendFCMNotification = onDocumentCreated({
  document: 'fcm_notifications/{notificationId}',
  region: 'us-central1'
}, async (event) => {
  try {
    const snapshot = event.data;
    if (!snapshot) {
      console.log('No data associated with the event');
      return null;
    }
    
    const notificationData = snapshot.data();
    
    // FCM 토큰 확인
    if (!notificationData.to) {
      console.log('FCM token missing in notification data:', JSON.stringify(notificationData));
      return null;
    }
    
    // 토큰이 유효한지 검증
    if (typeof notificationData.to !== 'string' || notificationData.to.length < 10) {
      console.log('Invalid FCM token format:', notificationData.to);
      return null;
    }

    console.log('Valid FCM token found (first 10 chars):', notificationData.to.substring(0, 10) + "...");

    // FCM 메시지 구성
    const message = {
      token: notificationData.to,
      notification: {
        title: notificationData.data?.title || '새 알림',
        body: notificationData.data?.body || '새로운 알림이 도착했습니다.',
      },
      data: notificationData.data || {},
      android: {
        notification: {
          channelId: 'game_challenges',
          priority: 'high',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // 메시지 전송
    const response = await admin.messaging().send(message);
    console.log('Successfully sent FCM notification:', response);
    
    // 전송 상태 업데이트
    await snapshot.ref.update({
      'sent': true,
      'sentAt': admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error sending FCM notification:', error);
    return { error: error.message };
  }
});
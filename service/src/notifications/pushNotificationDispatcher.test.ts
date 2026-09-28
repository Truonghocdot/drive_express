import assert from 'node:assert/strict';
import test from 'node:test';

import { WorkerEventEnvelope } from '../contracts/event.js';
import { PushNotification, PushSendResult, PushSender } from './firebasePushSender.js';
import { PushNotificationDispatcher } from './pushNotificationDispatcher.js';
import {
  NotificationClient,
  NotificationDispatchPayload,
} from './workerNotificationClient.js';

test('dispatches notification events and revokes invalid tokens', async () => {
  const sent: PushNotification[] = [];
  const revoked: string[] = [];
  const worker: NotificationClient = {
    async getDispatchPayload(): Promise<NotificationDispatchPayload> {
      return {
        id: 'notification-1',
        userId: 'user-1',
        type: 'CHAT_MESSAGE_RECEIVED',
        data: { conversation_id: 'conversation-1' },
        devices: [{
          appType: 'CUSTOMER_APP',
          tokens: ['valid-token', 'expired-token'],
        }, {
          appType: 'DRIVER_APP',
          tokens: ['driver-token'],
        }],
      };
    },
    async revokePushToken(token: string): Promise<void> {
      revoked.push(token);
    },
  };
  const sender: PushSender = {
    enabled: true,
    async send(notification: PushNotification): Promise<PushSendResult> {
      sent.push(notification);
      return {
        successCount: 1,
        failureCount: notification.appType === 'CUSTOMER_APP' ? 1 : 0,
        invalidTokens: notification.appType === 'CUSTOMER_APP' ? ['expired-token'] : [],
      };
    },
  };

  await new PushNotificationDispatcher(worker, sender).dispatch(event());

  assert.equal(sent.length, 2);
  assert.equal(sent[0]?.appType, 'CUSTOMER_APP');
  assert.equal(sent[1]?.appType, 'DRIVER_APP');
  assert.deepEqual(sent[0]?.tokens, ['valid-token', 'expired-token']);
  assert.deepEqual(revoked, ['expired-token']);
});

test('does not dispatch the same event twice', async () => {
  let calls = 0;
  const worker: NotificationClient = {
    async getDispatchPayload(): Promise<NotificationDispatchPayload> {
      return {
        id: 'notification-1',
        userId: 'user-1',
        type: 'TEST',
        data: {},
        devices: [{ appType: 'DRIVER_APP', tokens: ['token'] }],
      };
    },
    async revokePushToken(): Promise<void> {},
  };
  const sender: PushSender = {
    enabled: true,
    async send(): Promise<PushSendResult> {
      calls++;
      return { successCount: 1, failureCount: 0, invalidTokens: [] };
    },
  };
  const dispatcher = new PushNotificationDispatcher(worker, sender);

  await dispatcher.dispatch(event());
  await dispatcher.dispatch(event());

  assert.equal(calls, 1);
});

test('ignores non-notification events', async () => {
  let calls = 0;
  const worker: NotificationClient = {
    async getDispatchPayload(): Promise<NotificationDispatchPayload | null> {
      calls++;
      return null;
    },
    async revokePushToken(): Promise<void> {},
  };
  const sender: PushSender = {
    enabled: true,
    async send(): Promise<PushSendResult> {
      return { successCount: 0, failureCount: 0, invalidTokens: [] };
    },
  };

  await new PushNotificationDispatcher(worker, sender).dispatch({
    ...event(),
    event_type: 'DRIVER_ASSIGNED',
  });

  assert.equal(calls, 0);
});

function event(): WorkerEventEnvelope {
  return {
    event_id: 'event-1',
    event_type: 'NOTIFICATION_CREATED',
    aggregate_type: 'NOTIFICATION',
    aggregate_id: 0,
    aggregate_version: null,
    payload: { notification_id: 'notification-1', user_id: 'user-1', type: 'TEST' },
    occurred_at: '2026-09-28T00:00:00Z',
  };
}

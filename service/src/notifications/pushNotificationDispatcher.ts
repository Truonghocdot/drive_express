import { WorkerEventEnvelope } from '../contracts/event.js';
import { PushSender } from './firebasePushSender.js';
import { NotificationClient } from './workerNotificationClient.js';

export class PushNotificationDispatcher {
  private readonly seenEventIds = new Set<string>();

  public constructor(
    private readonly worker: NotificationClient,
    private readonly sender: PushSender,
    private readonly logger: Pick<Console, 'error' | 'warn'> = console,
  ) {}

  public async dispatch(event: WorkerEventEnvelope): Promise<void> {
    if (!this.sender.enabled || event.event_type !== 'NOTIFICATION_CREATED') {
      return;
    }

    if (this.seenEventIds.has(event.event_id)) {
      return;
    }
    this.seenEventIds.add(event.event_id);

    const notificationId = event.payload.notification_id;
    if (typeof notificationId !== 'string') {
      this.logger.warn(`Notification event ${event.event_id} has no notification_id`);
      return;
    }

    try {
      const notification = await this.worker.getDispatchPayload(notificationId);
      if (!notification || notification.devices.length === 0) {
        return;
      }

      for (const device of notification.devices) {
        const result = await this.sender.send({
          ...notification,
          appType: device.appType,
          tokens: device.tokens,
        });
        await Promise.all(result.invalidTokens.map(async (token) => {
          try {
            await this.worker.revokePushToken(token);
          } catch (error) {
            this.logger.warn(`Failed to revoke invalid FCM token: ${errorMessage(error)}`);
          }
        }));
      }
    } catch (error) {
      this.logger.error(`Push notification dispatch failed: ${errorMessage(error)}`);
    }
  }
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

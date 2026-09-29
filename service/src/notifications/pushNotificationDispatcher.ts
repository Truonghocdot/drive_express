import { WorkerEventEnvelope } from '../contracts/event.js';
import { PushSender } from './firebasePushSender.js';
import { NotificationClient } from './workerNotificationClient.js';

export class PushNotificationDispatcher {
  private readonly seenEventIds = new Set<string>();

  public constructor(
    private readonly worker: NotificationClient,
    private readonly sender: PushSender,
    private readonly logger: Pick<Console, 'error' | 'warn' | 'info'> = console,
    private readonly debug = false,
  ) {}

  public async dispatch(event: WorkerEventEnvelope): Promise<void> {
    if (event.event_type !== 'NOTIFICATION_CREATED') {
      return;
    }
    if (!this.sender.enabled) {
      this.trace('skip: Firebase credentials are not configured', event);
      return;
    }

    if (this.seenEventIds.has(event.event_id)) {
      this.trace('skip: duplicate event', event);
      return;
    }
    this.seenEventIds.add(event.event_id);

    const notificationId = event.payload.notification_id;
    if (typeof notificationId !== 'string') {
      this.logger.warn(`Notification event ${event.event_id} has no notification_id`);
      return;
    }

    try {
      this.trace(`lookup notification ${notificationId}`, event);
      const notification = await this.worker.getDispatchPayload(notificationId);
      if (!notification || notification.devices.length === 0) {
        this.trace(`skip: notification ${notificationId} has no active device`, event);
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
        this.trace(
          `sent ${notification.id} to ${device.appType}: success=${result.successCount}, failure=${result.failureCount}, invalid=${result.invalidTokens.length}`,
          event,
        );
      }
    } catch (error) {
      this.logger.error(`Push notification dispatch failed: ${errorMessage(error)}`);
    }
  }

  private trace(message: string, event: WorkerEventEnvelope): void {
    if (!this.debug) return;
    this.logger.info(`[push] event=${event.event_id} type=${event.event_type} ${message}`);
  }
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

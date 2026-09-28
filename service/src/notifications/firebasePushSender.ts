import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getMessaging, type MulticastMessage } from 'firebase-admin/messaging';

export interface PushNotification {
  id: string;
  appType: string;
  type: string;
  data: Record<string, unknown>;
  tokens: string[];
}

export interface PushSendResult {
  successCount: number;
  failureCount: number;
  invalidTokens: string[];
}

export interface PushSender {
  readonly enabled: boolean;
  send(notification: PushNotification): Promise<PushSendResult>;
}

export class FirebasePushSender implements PushSender {
  private readonly apps = new Map<string, App>();

  public constructor(
    configs: Record<string, FirebaseServiceAccount | undefined> = {
      CUSTOMER_APP: serviceAccount('FIREBASE_CUSTOMER'),
      DRIVER_APP: serviceAccount('FIREBASE_DRIVER'),
    },
  ) {
    for (const [appType, config] of Object.entries(configs)) {
      if (!config?.projectId || !config.clientEmail || !config.privateKey) {
        continue;
      }

      const appName = `push-${appType.toLowerCase()}`;
      const existing = getApps().find(
        (candidate) => candidate.options.projectId === config.projectId || candidate.name === appName,
      );
      const app = existing ?? initializeApp({
        credential: cert({
          projectId: config.projectId,
          clientEmail: config.clientEmail,
          privateKey: config.privateKey.replace(/\\n/g, '\n'),
        }),
      }, appName);
      this.apps.set(appType, app);
    }
  }

  public get enabled(): boolean {
    return this.apps.size > 0;
  }

  public async send(notification: PushNotification): Promise<PushSendResult> {
    const app = this.apps.get(notification.appType);
    if (!app || notification.tokens.length === 0) {
      return { successCount: 0, failureCount: 0, invalidTokens: [] };
    }

    let successCount = 0;
    let failureCount = 0;
    const invalidTokens: string[] = [];

    for (const tokens of chunks(notification.tokens, 500)) {
      const message: MulticastMessage = {
        tokens,
        notification: {
          title: titleFor(notification.type),
          body: bodyFor(notification.type),
        },
        data: {
          notification_id: notification.id,
          type: notification.type,
          ...stringifyData(notification.data),
        },
      };
      const response = await getMessaging(app).sendEachForMulticast(message);

      successCount += response.successCount;
      failureCount += response.failureCount;
      response.responses.forEach((result, index) => {
        const code = result.error?.code;
        if (
          code === 'messaging/registration-token-not-registered'
          || code === 'messaging/invalid-registration-token'
        ) {
          invalidTokens.push(tokens[index]);
        }
      });
    }

    return { successCount, failureCount, invalidTokens };
  }
}

export interface FirebaseServiceAccount {
  projectId?: string;
  clientEmail?: string;
  privateKey?: string;
}

function serviceAccount(prefix: string): FirebaseServiceAccount | undefined {
  const projectId = process.env[`${prefix}_PROJECT_ID`];
  const clientEmail = process.env[`${prefix}_CLIENT_EMAIL`];
  const privateKey = process.env[`${prefix}_PRIVATE_KEY`];

  if (!projectId || !clientEmail || !privateKey) {
    return undefined;
  }

  return { projectId, clientEmail, privateKey };
}

function chunks<T>(items: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

function stringifyData(data: Record<string, unknown>): Record<string, string> {
  return Object.fromEntries(
    Object.entries(data)
      .map(([key, value]) => [
        key,
        typeof value === 'string'
          ? value
          : typeof value === 'number' || typeof value === 'boolean'
            ? String(value)
            : JSON.stringify(value),
      ])
      .filter((entry): entry is [string, string] => typeof entry[1] === 'string'),
  );
}

function titleFor(type: string): string {
  if (type === 'CHAT_MESSAGE_RECEIVED') {
    return 'New message';
  }

  if (type.startsWith('SUPPORT_TICKET')) {
    return 'Support update';
  }

  if (type.startsWith('INCIDENT')) {
    return 'Incident update';
  }

  return 'New notification';
}

function bodyFor(type: string): string {
  if (type === 'CHAT_MESSAGE_RECEIVED') {
    return 'You have a new message.';
  }

  if (type === 'DRIVER_ASSIGNED') {
    return 'Your request has been assigned to a driver.';
  }

  if (type === 'SERVICE_REQUEST_CANCELLED') {
    return 'Your service request was cancelled.';
  }

  return 'There is a new update in the app.';
}

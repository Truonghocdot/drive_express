export interface NotificationDispatchPayload {
  id: string;
  userId: string;
  type: string;
  data: Record<string, unknown>;
  devices: NotificationDeviceBatch[];
}

export interface NotificationDeviceBatch {
  appType: string;
  tokens: string[];
}

export interface NotificationClient {
  getDispatchPayload(notificationId: string): Promise<NotificationDispatchPayload | null>;
  revokePushToken(pushToken: string): Promise<void>;
}

interface DispatchResponse {
  data?: {
    id?: unknown;
    user_id?: unknown;
    type?: unknown;
    data?: unknown;
    devices?: unknown;
  };
}

export class WorkerNotificationClient implements NotificationClient {
  public constructor(
    private readonly workerApiUrl: string,
    private readonly internalToken: string,
  ) {}

  public async getDispatchPayload(notificationId: string): Promise<NotificationDispatchPayload | null> {
    const response = await fetch(this.url(`/internal/notifications/${encodeURIComponent(notificationId)}/dispatch`), {
      headers: this.headers(),
    });

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error(`Worker notification lookup failed with HTTP ${response.status}`);
    }

    const body = await response.json() as DispatchResponse;
    const data = body.data;

    if (
      !data
      || typeof data.id !== 'string'
      || typeof data.user_id !== 'string'
      || typeof data.type !== 'string'
      || !isRecord(data.data)
      || !Array.isArray(data.devices)
    ) {
      throw new Error('Worker notification lookup returned an invalid payload');
    }

    const devices = data.devices
      .filter(isRecord)
      .map((device): NotificationDeviceBatch | null => {
        if (typeof device.app_type !== 'string' || !Array.isArray(device.tokens)) {
          return null;
        }

        return {
          appType: device.app_type,
          tokens: device.tokens.filter(
            (token): token is string => typeof token === 'string' && token.length > 0,
          ),
        };
      })
      .filter((device): device is NotificationDeviceBatch => device !== null && device.tokens.length > 0);

    return {
      id: data.id,
      userId: data.user_id,
      type: data.type,
      data: data.data,
      devices,
    };
  }

  public async revokePushToken(pushToken: string): Promise<void> {
    const response = await fetch(this.url('/internal/devices/revoke-push-token'), {
      method: 'POST',
      headers: {
        ...this.headers(),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ push_token: pushToken }),
    });

    if (!response.ok) {
      throw new Error(`Worker push token revocation failed with HTTP ${response.status}`);
    }
  }

  private headers(): Record<string, string> {
    return {
      Accept: 'application/json',
      'X-Internal-Service-Token': this.internalToken,
    };
  }

  private url(path: string): string {
    return this.workerApiUrl.replace(/\/$/, '') + path;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

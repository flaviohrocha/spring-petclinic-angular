interface RuntimeWindow extends Window {
  __PETCLINIC_CONFIG__?: {
    REST_API_URL: string;
  };
}

export function getRuntimeApiUrl(): string | undefined {
  return (window as RuntimeWindow).__PETCLINIC_CONFIG__?.REST_API_URL;
}

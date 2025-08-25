// app/lib/api.ts
export function apiBase(): string {
  // IMPORTANT: accès statique à la clé VITE_ (pas d'accès dynamique à import.meta.env)
  const base = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:1440';
  return String(base).replace(/\/+$/, '');
}

export function apiUrl(path: string): string {
  const base = apiBase();
  const p = path.startsWith('/api') ? path : `/api${path}`;
  return `${base}${p}`;
}

export function authHeaders(): Record<string, string> {
  // IMPORTANT: accès statique aussi ici
  const token = import.meta.env.VITE_STRAPI_TOKEN;
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

export async function getJSON<T>(path: string): Promise<T> {
  const res = await fetch(apiUrl(path), { headers: authHeaders() });
  const text = await res.text();
  const payload = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const msg =
      (payload && (payload.error?.message || payload.message)) ||
      `HTTP ${res.status}`;
    throw new Error(msg);
  }
  return payload as T;
}

export function absMediaUrl(url?: string | null): string {
  if (!url) return '/images/no-image.png';
  if (/^https?:\/\//i.test(url)) return url;
  return `${apiBase()}${url}`;
}

export type Listing = {
  id: string
  title: string
  brand: string
  url: string
  price: string | number | null
  currency: string
  category: string | null
  createdAt: string
}

const ADMIN_KEY_STORAGE = 'ai-styler-admin-key'

export function getAdminKey(): string {
  return sessionStorage.getItem(ADMIN_KEY_STORAGE) ?? ''
}

export function setAdminKey(key: string): void {
  sessionStorage.setItem(ADMIN_KEY_STORAGE, key)
}

async function adminFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const key = getAdminKey()
  const headers = new Headers(init.headers)
  headers.set('X-Admin-Key', key)
  const response = await fetch(path, { ...init, headers })
  if (response.status === 401) {
    throw new Error('Invalid admin key. Update it in the header and try again.')
  }
  return response
}

export async function fetchListings(): Promise<Listing[]> {
  const response = await adminFetch('/admin/listings')
  if (!response.ok) {
    throw new Error(await readError(response))
  }
  return response.json()
}

export async function fetchListing(id: string): Promise<Listing> {
  const response = await adminFetch(`/admin/listings/${id}`)
  if (!response.ok) {
    throw new Error(await readError(response))
  }
  return response.json()
}

export async function createListing(form: FormData): Promise<Listing> {
  const response = await adminFetch('/admin/listings', {
    method: 'POST',
    body: form,
  })
  if (!response.ok) {
    throw new Error(await readError(response))
  }
  return response.json()
}

export async function deleteListing(id: string): Promise<void> {
  const response = await adminFetch(`/admin/listings/${id}`, { method: 'DELETE' })
  if (!response.ok) {
    throw new Error(await readError(response))
  }
}

async function readError(response: Response): Promise<string> {
  try {
    const data = await response.json()
    if (typeof data.detail === 'string') return data.detail
    return JSON.stringify(data.detail ?? data)
  } catch {
    return `Request failed (${response.status})`
  }
}

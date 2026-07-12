import { useEffect, useState } from 'react'
import { getAdminKey } from '../api'

type Props = {
  listingId: string
  alt: string
  className?: string
}

export default function ListingImage({ listingId, alt, className }: Props) {
  const [src, setSrc] = useState<string | null>(null)
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    let objectUrl: string | null = null
    let cancelled = false

    async function load() {
      try {
        const response = await fetch(`/admin/listings/${listingId}/image`, {
          headers: { 'X-Admin-Key': getAdminKey() },
        })
        if (!response.ok) throw new Error('image failed')
        const blob = await response.blob()
        if (cancelled) return
        objectUrl = URL.createObjectURL(blob)
        setSrc(objectUrl)
        setFailed(false)
      } catch {
        if (!cancelled) setFailed(true)
      }
    }

    load()
    return () => {
      cancelled = true
      if (objectUrl) URL.revokeObjectURL(objectUrl)
    }
  }, [listingId])

  if (failed) return <div className={className}>No image</div>
  if (!src) return <div className={className} aria-hidden />
  return <img src={src} alt={alt} className={className} />
}

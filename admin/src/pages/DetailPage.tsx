import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { deleteListing, fetchListing, type Listing } from '../api'
import ListingImage from '../components/ListingImage'

export default function DetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [listing, setListing] = useState<Listing | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => {
    if (!id) return
    let cancelled = false
    fetchListing(id)
      .then((data) => {
        if (!cancelled) {
          setListing(data)
          setError(null)
        }
      })
      .catch((err: Error) => {
        if (!cancelled) setError(err.message)
      })
    return () => {
      cancelled = true
    }
  }, [id])

  async function onDelete() {
    if (!id || !listing) return
    if (!confirm(`Delete “${listing.title}”?`)) return
    setDeleting(true)
    try {
      await deleteListing(id)
      navigate('/')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Delete failed')
      setDeleting(false)
    }
  }

  if (error && !listing) return <p className="error">{error}</p>
  if (!listing) return <p className="muted">Loading…</p>

  return (
    <div>
      <p className="back">
        <Link to="/">← All listings</Link>
      </p>
      <div className="detail">
        <ListingImage
          listingId={listing.id}
          alt={listing.title}
          className="detail-image"
        />
        <div className="detail-body">
          <p className="card-brand">{listing.brand}</p>
          <h1>{listing.title}</h1>
          <dl className="fields">
            <dt>Price</dt>
            <dd>
              {listing.price != null && listing.price !== ''
                ? `${listing.currency} ${listing.price}`
                : '—'}
            </dd>
            <dt>Category</dt>
            <dd>{listing.category ?? '—'}</dd>
            <dt>Product URL</dt>
            <dd>
              <a href={listing.url} target="_blank" rel="noreferrer">
                {listing.url}
              </a>
            </dd>
            <dt>Added</dt>
            <dd>{new Date(listing.createdAt).toLocaleString()}</dd>
          </dl>
          {error && <p className="error">{error}</p>}
          <button
            type="button"
            className="button danger"
            onClick={onDelete}
            disabled={deleting}
          >
            {deleting ? 'Deleting…' : 'Delete listing'}
          </button>
        </div>
      </div>
    </div>
  )
}

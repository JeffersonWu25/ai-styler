import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchListings, type Listing } from '../api'
import ListingImage from '../components/ListingImage'

export default function ListingsPage() {
  const [listings, setListings] = useState<Listing[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    fetchListings()
      .then((data) => {
        if (!cancelled) {
          setListings(data)
          setError(null)
        }
      })
      .catch((err: Error) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [])

  if (loading) return <p className="muted">Loading listings…</p>
  if (error) return <p className="error">{error}</p>

  if (listings.length === 0) {
    return (
      <div className="empty">
        <p>No listings yet.</p>
        <Link to="/new" className="button">
          Add your first listing
        </Link>
      </div>
    )
  }

  return (
    <div>
      <div className="page-header">
        <h1>Listings</h1>
        <Link to="/new" className="button">
          Add listing
        </Link>
      </div>
      <div className="grid">
        {listings.map((listing) => (
          <Link key={listing.id} to={`/item/${listing.id}`} className="card">
            <ListingImage
              listingId={listing.id}
              alt={listing.title}
              className="thumb"
            />
            <div className="card-body">
              <p className="card-brand">{listing.brand}</p>
              <h2 className="card-title">{listing.title}</h2>
              <p className="card-meta">
                {formatPrice(listing)}
                {listing.category ? ` · ${listing.category}` : ''}
              </p>
            </div>
          </Link>
        ))}
      </div>
    </div>
  )
}

function formatPrice(listing: Listing): string {
  if (listing.price == null || listing.price === '') return 'No price'
  return `${listing.currency} ${listing.price}`
}

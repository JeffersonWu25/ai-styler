import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { createListing } from '../api'

const CATEGORIES = ['jacket', 'pants', 'shoes', 'top', 'accessory', 'other']

export default function CreatePage() {
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [preview, setPreview] = useState<string | null>(null)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setSaving(true)
    setError(null)
    const form = new FormData(event.currentTarget)
    try {
      const listing = await createListing(form)
      navigate(`/item/${listing.id}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Create failed')
      setSaving(false)
    }
  }

  function onImageChange(file: File | null) {
    if (preview) URL.revokeObjectURL(preview)
    setPreview(file ? URL.createObjectURL(file) : null)
  }

  return (
    <div className="form-page">
      <h1>Add listing</h1>
      <form className="form" onSubmit={onSubmit}>
        <label>
          Title
          <input name="title" required placeholder="Relaxed Fit Denim Jacket" />
        </label>
        <label>
          Brand
          <input name="brand" required placeholder="Stüssy" />
        </label>
        <label>
          Product URL
          <input
            name="url"
            type="url"
            required
            placeholder="https://..."
          />
        </label>
        <div className="row">
          <label>
            Price
            <input name="price" type="number" step="0.01" min="0" placeholder="128" />
          </label>
          <label>
            Currency
            <input name="currency" defaultValue="USD" maxLength={3} />
          </label>
          <label>
            Category
            <select name="category" defaultValue="">
              <option value="">—</option>
              {CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </label>
        </div>
        <label>
          Image
          <input
            name="image"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            required
            onChange={(e) => onImageChange(e.target.files?.[0] ?? null)}
          />
        </label>
        {preview && (
          <img src={preview} alt="Preview" className="form-preview" />
        )}
        {error && <p className="error">{error}</p>}
        <button type="submit" className="button" disabled={saving}>
          {saving ? 'Saving…' : 'Save listing'}
        </button>
      </form>
    </div>
  )
}

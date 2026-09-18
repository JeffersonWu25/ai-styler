import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { createListing } from '../api'

const CATEGORIES = ['jacket', 'pants', 'shoes', 'top', 'accessory', 'other']
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp'])

export default function CreatePage() {
  const navigate = useNavigate()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)

  useEffect(() => {
    return () => {
      if (preview) URL.revokeObjectURL(preview)
    }
  }, [preview])

  useEffect(() => {
    function onPaste(event: ClipboardEvent) {
      const items = event.clipboardData?.items
      if (!items) return

      for (const item of items) {
        if (!item.type.startsWith('image/')) continue
        const file = item.getAsFile()
        if (!file) continue
        event.preventDefault()
        applyImage(file)
        return
      }
    }

    window.addEventListener('paste', onPaste)
    return () => window.removeEventListener('paste', onPaste)
  }, [])

  function applyImage(file: File) {
    if (!ALLOWED_TYPES.has(file.type) && file.type !== '') {
      // Some clipboard sources omit type; still accept if named like an image.
      if (!file.type.startsWith('image/')) {
        setError('Pasted file must be a JPEG, PNG, or WebP image.')
        return
      }
    }

    const normalized =
      file.type && ALLOWED_TYPES.has(file.type)
        ? file
        : new File([file], file.name || 'pasted-image.png', {
            type: file.type || 'image/png',
          })

    setImageFile(normalized)
    setPreview((prev) => {
      if (prev) URL.revokeObjectURL(prev)
      return URL.createObjectURL(normalized)
    })
    setError(null)

    if (fileInputRef.current) {
      const transfer = new DataTransfer()
      transfer.items.add(normalized)
      fileInputRef.current.files = transfer.files
    }
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!imageFile) {
      setError('Add an image — upload a file or paste one (⌘V / Ctrl+V).')
      return
    }

    setSaving(true)
    setError(null)
    const form = new FormData(event.currentTarget)
    form.set('image', imageFile)

    try {
      const listing = await createListing(form)
      navigate(`/item/${listing.id}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Create failed')
      setSaving(false)
    }
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

        <div className="image-field">
          <span className="image-label">Image</span>
          <div
            className={`paste-zone${imageFile ? ' has-image' : ''}`}
            tabIndex={0}
            role="button"
            aria-label="Paste or upload product image"
            onClick={() => fileInputRef.current?.click()}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault()
                fileInputRef.current?.click()
              }
            }}
          >
            {preview ? (
              <img src={preview} alt="Preview" className="form-preview" />
            ) : (
              <p>
                Paste an image here (⌘V / Ctrl+V), or click to upload
              </p>
            )}
          </div>
          <input
            ref={fileInputRef}
            name="image"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="file-input-hidden"
            onChange={(e) => {
              const file = e.target.files?.[0] ?? null
              if (file) applyImage(file)
            }}
          />
          {imageFile && (
            <p className="muted image-filename">{imageFile.name}</p>
          )}
        </div>

        {error && <p className="error">{error}</p>}
        <button type="submit" className="button" disabled={saving}>
          {saving ? 'Saving…' : 'Save listing'}
        </button>
      </form>
    </div>
  )
}

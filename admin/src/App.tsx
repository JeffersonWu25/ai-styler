import { Link, NavLink, Outlet } from 'react-router-dom'
import { getAdminKey, setAdminKey } from './api'
import { useState } from 'react'
import './App.css'

export default function App() {
  const [adminKey, setAdminKeyState] = useState(getAdminKey())

  function onKeyChange(value: string) {
    setAdminKey(value)
    setAdminKeyState(value)
  }

  return (
    <div className="app">
      <header className="header">
        <Link to="/" className="brand">
          AI Styler Admin
        </Link>
        <nav className="nav">
          <NavLink to="/" end>
            Listings
          </NavLink>
          <NavLink to="/new">Add listing</NavLink>
        </nav>
        <label className="admin-key">
          Admin key
          <input
            type="password"
            value={adminKey}
            onChange={(e) => onKeyChange(e.target.value)}
            placeholder="ADMIN_API_KEY"
            autoComplete="off"
          />
        </label>
      </header>
      <main className="main">
        <Outlet />
      </main>
    </div>
  )
}

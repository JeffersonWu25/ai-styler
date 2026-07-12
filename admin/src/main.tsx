import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import App from './App'
import CreatePage from './pages/CreatePage'
import DetailPage from './pages/DetailPage'
import ListingsPage from './pages/ListingsPage'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter basename="/admin">
      <Routes>
        <Route element={<App />}>
          <Route index element={<ListingsPage />} />
          <Route path="new" element={<CreatePage />} />
          <Route path="item/:id" element={<DetailPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </StrictMode>,
)

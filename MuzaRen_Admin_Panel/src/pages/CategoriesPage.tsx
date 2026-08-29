import { useEffect, useState, useCallback } from 'react'
import type { FormEvent } from 'react'
import { createCategory, deleteCategory, fetchCategories, updateCategory } from '../services/adminApi'
import type { AdminCategory, Pagination as PaginationType } from '../types/admin'
import { Edit2, Trash2, Plus, PackageOpen, Search } from 'lucide-react'
import { usePagination } from '../hooks/usePagination'
import Pagination from '../components/shared/Pagination'

const DEFAULT_ICONS = ['📦', '📱', '🏠', '🚗', '👗', '⚽', '🎸', '🌿', '🛠️', '📷', '💼', '🎮']

export function CategoriesPage() {
  const { page, limit, setPage, resetPagination } = usePagination(50)
  const [categories, setCategories] = useState<AdminCategory[]>([])
  const [pagination, setPagination] = useState<PaginationType | null>(null)
  
  const [search, setSearch] = useState('')
  const [name, setName] = useState('')
  const [icon, setIcon] = useState('📦')
  const [editingCategoryId, setEditingCategoryId] = useState<string | null>(null)
  const [editName, setEditName] = useState('')
  const [editIcon, setEditIcon] = useState('📦')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [isLoading, setIsLoading] = useState(true)

  const clearMessages = () => { setError(''); setSuccess('') }

  const loadCategories = useCallback(async () => {
    setIsLoading(true)
    setError('')
    try {
      const result = await fetchCategories({
        search: search.trim(),
        page,
        limit,
      })
      setCategories(result.data)
      setPagination(result.pagination)
    } catch {
      setError('Failed to load categories.')
    } finally {
      setIsLoading(false)
    }
  }, [search, page, limit])

  useEffect(() => {
    const timer = setTimeout(() => {
      loadCategories()
    }, search ? 500 : 0)
    return () => clearTimeout(timer)
  }, [loadCategories])

  const handleFilterChange = (setter: (val: string) => void, val: string) => {
    setter(val)
    resetPagination()
  }

  const handleCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    clearMessages()
    try {
      await createCategory({ name: name.trim(), icon })
      setName('')
      setIcon('📦')
      setSuccess(`Category "${name}" created.`)
      await loadCategories()
    } catch {
      setError('Failed to create category. Name may already exist.')
    }
  }

  const startEdit = (category: AdminCategory) => {
    clearMessages()
    setEditingCategoryId(category.id)
    setEditName(category.name)
    setEditIcon(category.icon ?? '📦')
  }

  const cancelEdit = () => {
    setEditingCategoryId(null)
    setEditName('')
    setEditIcon('📦')
  }

  const handleUpdate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!editingCategoryId) return
    clearMessages()
    try {
      await updateCategory(editingCategoryId, { name: editName.trim(), icon: editIcon })
      cancelEdit()
      setSuccess('Category updated.')
      await loadCategories()
    } catch {
      setError('Failed to update category.')
    }
  }

  const handleDelete = async (category: AdminCategory) => {
    if (!window.confirm(`Delete "${category.name}"? Listings using this category may be affected.`)) return
    clearMessages()
    try {
      await deleteCategory(category.id)
      setSuccess(`Category "${category.name}" deleted.`)
      await loadCategories()
    } catch {
      setError('Failed to delete category. It may have listings attached to it.')
    }
  }

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      
      {error && (
        <div style={{ padding: '1rem', background: 'var(--danger-subtle)', color: 'var(--danger)', borderRadius: '8px' }}>
          {error}
        </div>
      )}
      {success && (
        <div style={{ padding: '1rem', background: 'var(--success-subtle)', color: 'var(--success)', borderRadius: '8px' }}>
          {success}
        </div>
      )}

      {/* Forms Section */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1.5rem', maxWidth: '800px' }}>
        <div className="card">
          <div style={{ paddingBottom: '1rem', marginBottom: '1.25rem', borderBottom: '1px solid var(--gray-100)' }}>
            <h3 style={{ margin: 0 }}>Add new category</h3>
            <p className="muted" style={{ fontSize: '0.875rem', marginTop: '4px' }}>Create a new top-level classification for listings.</p>
          </div>
          <form onSubmit={handleCreate} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            <div className="form-row">
              <div className="form-group" style={{ flex: 2 }}>
                <label htmlFor="cat-name">Category name</label>
                <input
                  id="cat-name"
                  type="text"
                  required
                  placeholder="e.g. Electronics"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
              </div>
              <div className="form-group" style={{ flex: 1, minWidth: '120px' }}>
                <label htmlFor="cat-icon">Icon (emoji)</label>
                <input
                  id="cat-icon"
                  type="text"
                  placeholder="📦"
                  value={icon}
                  onChange={(e) => setIcon(e.target.value || '📦')}
                  style={{ fontSize: '1.25rem', textAlign: 'center' }}
                />
              </div>
            </div>
            
            <div className="form-group">
              <label>Quick select icons</label>
              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                {DEFAULT_ICONS.map((em) => (
                  <button
                    key={em}
                    type="button"
                    className={`emoji-btn ${icon === em ? 'active' : ''}`}
                    onClick={() => setIcon(em)}
                  >
                    {em}
                  </button>
                ))}
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
              <button id="create-category-btn" type="submit" className="btn btn-primary">
                <Plus size={16} /> Add category
              </button>
            </div>
          </form>
        </div>

        {editingCategoryId && (
          <div className="card" style={{ borderLeft: '4px solid var(--warning)' }}>
            <div style={{ paddingBottom: '1rem', marginBottom: '1.25rem', borderBottom: '1px solid var(--gray-100)' }}>
              <h3 style={{ margin: 0 }}>Edit category</h3>
            </div>
            <form onSubmit={handleUpdate} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div className="form-row">
                <div className="form-group" style={{ flex: 2 }}>
                  <label htmlFor="edit-cat-name">Category name</label>
                  <input
                    id="edit-cat-name"
                    type="text"
                    required
                    value={editName}
                    onChange={(e) => setEditName(e.target.value)}
                  />
                </div>
                <div className="form-group" style={{ flex: 1, minWidth: '120px' }}>
                  <label htmlFor="edit-cat-icon">Icon (emoji)</label>
                  <input
                    id="edit-cat-icon"
                    type="text"
                    value={editIcon}
                    onChange={(e) => setEditIcon(e.target.value || '📦')}
                    style={{ fontSize: '1.25rem', textAlign: 'center' }}
                  />
                </div>
              </div>
              <div className="form-group">
                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                  {DEFAULT_ICONS.map((em) => (
                    <button
                      key={em}
                      type="button"
                      className={`emoji-btn ${editIcon === em ? 'active' : ''}`}
                      onClick={() => setEditIcon(em)}
                    >
                      {em}
                    </button>
                  ))}
                </div>
              </div>
              <div className="action-row" style={{ justifyContent: 'flex-end', marginTop: '0.5rem' }}>
                <button type="button" className="btn btn-outline-gray" onClick={cancelEdit}>Cancel</button>
                <button id="save-category-btn" type="submit" className="btn btn-primary">Save changes</button>
              </div>
            </form>
          </div>
        )}
      </div>

      {/* Table Section */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 600 }}>All Categories</h3>
          <div className="search-input-wrap">
            <Search size={18} />
            <input
              type="search"
              placeholder="Search category name…"
              value={search}
              onChange={(e) => handleFilterChange(setSearch, e.target.value)}
              className="search-input"
            />
          </div>
        </div>
        
        <div className="table-wrap">
          {isLoading ? (
            <div className="empty-state">
              <span className="spinner" />
              <p>Loading categories…</p>
            </div>
          ) : categories.length === 0 ? (
            <div className="empty-state">
              <PackageOpen size={48} color="var(--gray-300)" />
              <h3>No categories match your search</h3>
            </div>
          ) : (
            <>
              <table>
                <thead>
                  <tr>
                    <th style={{ width: '60px' }}>Icon</th>
                    <th>Category Name</th>
                    <th>Slug Identifier</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {categories.map((category) => (
                    <tr key={category.id}>
                      <td>
                        <div style={{ width: '36px', height: '36px', borderRadius: '8px', background: 'var(--gray-100)', display: 'grid', placeItems: 'center', fontSize: '1.2rem' }}>
                          {category.icon ?? '📦'}
                        </div>
                      </td>
                      <td><strong style={{ color: 'var(--gray-900)' }}>{category.name}</strong></td>
                      <td><code className="code-chip">{category.slug}</code></td>
                      <td>
                        <div className="action-row" style={{ justifyContent: 'flex-end' }}>
                          <button
                            type="button"
                            className="btn btn-outline-gray"
                            onClick={() => startEdit(category)}
                          >
                            <Edit2 size={16} /> Edit
                          </button>
                          <button
                            type="button"
                            className="btn btn-outline-red"
                            onClick={() => handleDelete(category)}
                          >
                            <Trash2 size={16} /> Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {pagination && (
                <Pagination
                  {...pagination}
                  onPageChange={setPage}
                />
              )}
            </>
          )}
        </div>
      </div>
    </section>
  )
}

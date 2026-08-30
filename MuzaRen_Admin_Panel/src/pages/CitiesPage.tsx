import { useState, useEffect } from 'react'
import { Plus, Pencil, Trash2 } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { api } from '../services/api'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Table, Thead, Tbody, Tr, Th, Td } from '../components/ui/Table'
import { Input } from '../components/ui/Input'
import { LoadingSpinner } from '../components/ui/LoadingSpinner'

interface City {
  id: string
  name: string
  state: string
  country: string
  isActive: boolean
  createdAt: string
}

export function CitiesPage() {
  const [cities, setCities] = useState<City[]>([])
  const [loading, setLoading] = useState(true)
  
  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingCity, setEditingCity] = useState<City | null>(null)
  
  // Form state
  const [name, setName] = useState('')
  const [stateName, setStateName] = useState('')
  const [country, setCountry] = useState('India')
  const [isActive, setIsActive] = useState(true)

  useEffect(() => {
    fetchCities()
  }, [])

  const fetchCities = async () => {
    try {
      const { data } = await api.get('/admin/cities')
      setCities(data.data)
    } catch (error) {
      toast.error('Failed to load cities')
    } finally {
      setLoading(false)
    }
  }

  const openModal = (city?: City) => {
    if (city) {
      setEditingCity(city)
      setName(city.name)
      setStateName(city.state)
      setCountry(city.country)
      setIsActive(city.isActive)
    } else {
      setEditingCity(null)
      setName('')
      setStateName('')
      setCountry('India')
      setIsActive(true)
    }
    setIsModalOpen(true)
  }

  const closeModal = () => {
    setIsModalOpen(false)
    setEditingCity(null)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingCity) {
        await api.put(`/admin/cities/${editingCity.id}`, {
          name, state: stateName, country, isActive
        })
        toast.success('City updated successfully')
      } else {
        await api.post('/admin/cities', {
          name, state: stateName, country, isActive
        })
        toast.success('City added successfully')
      }
      closeModal()
      fetchCities()
    } catch (error) {
      toast.error('Failed to save city')
    }
  }

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this city?')) return
    try {
      await api.delete(`/admin/cities/${id}`)
      toast.success('City deleted')
      fetchCities()
    } catch (error) {
      toast.error('Failed to delete city')
    }
  }

  const toggleStatus = async (city: City) => {
    try {
      await api.put(`/admin/cities/${city.id}`, {
        isActive: !city.isActive
      })
      fetchCities()
    } catch (error) {
      toast.error('Failed to update status')
    }
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Serviceable Cities</h1>
          <p className="page-description">Manage locations where RentHubIndia is active.</p>
        </div>
        <Button onClick={() => openModal()}>
          <Plus size={16} style={{ marginRight: 8 }} />
          Add City
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Cities</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <Thead>
              <Tr>
                <Th>Name</Th>
                <Th>State</Th>
                <Th>Country</Th>
                <Th>Status</Th>
                <Th align="right">Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {cities.map((city) => (
                <Tr key={city.id}>
                  <Td><strong>{city.name}</strong></Td>
                  <Td>{city.state}</Td>
                  <Td>{city.country}</Td>
                  <Td>
                    <span 
                      onClick={() => toggleStatus(city)}
                      style={{ 
                        cursor: 'pointer',
                        padding: '4px 8px', 
                        borderRadius: 4, 
                        fontSize: 12,
                        backgroundColor: city.isActive ? '#e6f4ea' : '#fce8e6',
                        color: city.isActive ? '#137333' : '#c5221f'
                      }}
                    >
                      {city.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </Td>
                  <Td align="right">
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                      <Button variant="outline" size="sm" onClick={() => openModal(city)}>
                        <Pencil size={14} />
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => handleDelete(city.id)} style={{ color: 'var(--danger)' }}>
                        <Trash2 size={14} />
                      </Button>
                    </div>
                  </Td>
                </Tr>
              ))}
              {cities.length === 0 && (
                <Tr>
                  <Td colSpan={5} align="center">No cities found. Add one to get started.</Td>
                </Tr>
              )}
            </Tbody>
          </Table>
        </CardContent>
      </Card>

      {/* Basic Modal implementation */}
      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 1000,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <div style={{
            backgroundColor: 'white', padding: 24, borderRadius: 8, width: 400, maxWidth: '90%'
          }}>
            <h2 style={{ marginBottom: 16 }}>{editingCity ? 'Edit City' : 'Add City'}</h2>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 14 }}>City Name</label>
                <Input required value={name} onChange={(e: any) => setName(e.target.value)} placeholder="e.g. Mumbai" />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 14 }}>State (Optional)</label>
                <Input value={stateName} onChange={(e: any) => setStateName(e.target.value)} placeholder="e.g. Maharashtra" />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 14 }}>Country</label>
                <Input required value={country} onChange={(e: any) => setCountry(e.target.value)} placeholder="e.g. India" />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <input 
                  type="checkbox" 
                  id="isActive" 
                  checked={isActive} 
                  onChange={(e: any) => setIsActive(e.target.checked)} 
                />
                <label htmlFor="isActive">Serviceable (Active)</label>
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 8 }}>
                <Button variant="outline" type="button" onClick={closeModal}>Cancel</Button>
                <Button type="submit">Save City</Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}

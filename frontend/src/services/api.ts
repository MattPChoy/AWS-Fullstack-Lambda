import axios from 'axios'

const api = axios.create({
  baseURL: '',
  headers: {
    'Content-Type': 'application/json'
  }
})

export interface Item {
  id: string
  name: string
  description: string
  createdAt: string
}

export const itemsApi = {
  getAll: () => api.get<Item[]>('/api/items'),
  getById: (id: string) => api.get<Item>(`/api/items/${id}`),
  create: (item: Omit<Item, 'id' | 'createdAt'>) => api.post<Item>('/api/items', item),
  update: (id: string, item: Omit<Item, 'id' | 'createdAt'>) => api.put(`/api/items/${id}`, item),
  delete: (id: string) => api.delete(`/api/items/${id}`)
}

export default api

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { itemsApi, type Item } from '../services/api'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'

const items = ref<Item[]>([])
const loading = ref(false)
const itemForm = ref({
  name: '',
  description: ''
})
const editingItemId = ref<string | null>(null)

const loadItems = async () => {
  loading.value = true
  try {
    const response = await itemsApi.getAll()
    items.value = response.data
  } catch (error) {
    console.error('Error loading items:', error)
  } finally {
    loading.value = false
  }
}

const clearForm = () => {
  itemForm.value = { name: '', description: '' }
  editingItemId.value = null
}

const editItem = (item: Item) => {
  itemForm.value = {
    name: item.name,
    description: item.description
  }
  editingItemId.value = item.id
}

const saveItem = async () => {
  if (!itemForm.value.name.trim()) {
    alert('Name is required')
    return
  }

  try {
    if (editingItemId.value) {
      await itemsApi.update(editingItemId.value, itemForm.value)
    } else {
      await itemsApi.create(itemForm.value)
    }
    clearForm()
    await loadItems()
  } catch (error) {
    console.error('Error saving item:', error)
  }
}

const deleteItem = async (id: string) => {
  if (confirm('Are you sure you want to delete this item?')) {
    try {
      await itemsApi.delete(id)
      await loadItems()
    } catch (error) {
      console.error('Error deleting item:', error)
    }
  }
}

onMounted(() => {
  loadItems()
})
</script>

<template>
  <div class="items-container">
    <h1>Items Management</h1>

    <div class="form-card">
      <h2>{{ editingItemId ? 'Edit Item' : 'Add New Item' }}</h2>
      <div class="form-field">
        <label for="name">Name</label>
        <InputText id="name" v-model="itemForm.name" placeholder="Enter item name" />
      </div>

      <div class="form-field">
        <label for="description">Description</label>
        <Textarea id="description" v-model="itemForm.description" rows="3" placeholder="Enter item description" />
      </div>

      <div class="form-actions">
        <Button label="Save" icon="pi pi-check" @click="saveItem" />
        <Button v-if="editingItemId" label="Cancel" icon="pi pi-times" severity="secondary" @click="clearForm" />
      </div>
    </div>

    <DataTable :value="items" :loading="loading" stripedRows>
      <Column field="name" header="Name" />
      <Column field="description" header="Description" />
      <Column field="createdAt" header="Created At">
        <template #body="{ data }">
          {{ new Date(data.createdAt).toLocaleString() }}
        </template>
      </Column>
      <Column header="Actions">
        <template #body="{ data }">
          <Button icon="pi pi-pencil" severity="info" text @click="editItem(data)" />
          <Button icon="pi pi-trash" severity="danger" text @click="deleteItem(data.id)" />
        </template>
      </Column>
    </DataTable>
  </div>
</template>

<style scoped>
.items-container {
  padding: 2rem;
}

.form-card {
  background-color: #f8f9fa;
  padding: 1.5rem;
  border-radius: 8px;
  margin-bottom: 2rem;
  border: 1px solid #e9ecef;
}

.form-card h2 {
  margin-top: 0;
  margin-bottom: 1.5rem;
  font-size: 1.25rem;
  color: #333;
}

.form-field {
  margin-bottom: 1rem;
}

.form-field label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #495057;
}

.form-field input,
.form-field textarea {
  width: 100%;
}

:deep(.p-inputtext),
:deep(.p-inputtextarea) {
  background-color: #ffffff;
  color: #212529;
  border: 1px solid #ced4da;
  padding: 0.5rem 0.75rem;
}

:deep(.p-inputtext:focus),
:deep(.p-inputtextarea:focus) {
  border-color: #86b7fe;
  box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.25);
  outline: 0;
}

.form-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 1.5rem;
}

:deep(.p-button) {
  background-color: #0d6efd;
  color: #ffffff;
  border: 1px solid #0d6efd;
  padding: 0.5rem 1rem;
  cursor: pointer;
}

:deep(.p-button:hover) {
  background-color: #0b5ed7;
  border-color: #0a58ca;
}

:deep(.p-button.p-button-secondary) {
  background-color: #6c757d;
  border-color: #6c757d;
}

:deep(.p-button.p-button-secondary:hover) {
  background-color: #5c636a;
  border-color: #565e64;
}

:deep(.p-button-icon-only) {
  background-color: transparent;
  border-color: transparent;
  color: inherit;
}

:deep(.p-button-text) {
  background-color: transparent;
  border-color: transparent;
}

:deep(.p-button-info.p-button-text) {
  color: #0dcaf0;
}

:deep(.p-button-danger.p-button-text) {
  color: #dc3545;
}

:deep(.p-button-text:hover) {
  background-color: rgba(0, 0, 0, 0.05);
}
</style>

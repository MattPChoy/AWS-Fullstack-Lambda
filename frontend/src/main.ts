import { createApp } from 'vue'
import PrimeVue from 'primevue/config'
import './style.css'
import App from './App.vue'
import 'primeicons/primeicons.css'

const app = createApp(App)

app.use(PrimeVue, {
  ripple: true
})

app.mount('#app')

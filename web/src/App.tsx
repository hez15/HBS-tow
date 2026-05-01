import { useEffect, useState, useCallback } from 'react'
import Sidebar from './components/Sidebar'
import Home from './screens/Home'
import Calls from './screens/Calls'
import Active from './screens/Active'
import History from './screens/History'
import StatsScreen from './screens/Stats'
import { nuiFetch, onNuiMessage } from './nui'
import type { Stats, ActiveMission, Screen } from './types'

export default function App() {
  const [open, setOpen] = useState(false)
  const [screen, setScreen] = useState<Screen>('home')
  const [stats, setStats] = useState<Stats | null>(null)
  const [active, setActive] = useState<ActiveMission | null>(null)

  const loadAll = useCallback(async () => {
    const [s, a] = await Promise.all([
      nuiFetch<unknown, Stats>('getStats'),
      nuiFetch<unknown, ActiveMission | null>('getActive'),
    ])
    setStats(s)
    setActive(a)
  }, [])

  useEffect(() => {
    return onNuiMessage((msg) => {
      if (msg.action === 'open') {
        setOpen(true)
        setScreen('home')
        loadAll()
      } else if (msg.action === 'close') {
        setOpen(false)
      } else if (msg.action === 'updateActive') {
        setActive(msg.payload)
      }
    })
  }, [loadAll])

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (open && e.key === 'Escape') close()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open])

  async function close() {
    setOpen(false)
    await nuiFetch('close')
  }

  if (!open) return null

  return (
    <div className="w-full h-full flex items-center justify-center bg-black/40">
      <div className="w-[1100px] h-[720px] bg-base rounded-2xl border border-border flex overflow-hidden shadow-2xl">
        <Sidebar current={screen} onChange={(k) => setScreen(k as Screen)} onClose={close} />
        <div className="flex-1 p-8 overflow-y-auto">
          {screen === 'home' && (
            <Home
              stats={stats}
              active={active}
              onGo={() => setScreen('calls')}
            />
          )}
          {screen === 'calls' && <Calls onAccepted={close} />}
          {screen === 'active' && (
            <Active mission={active} onAbandon={() => { setActive(null); setScreen('home') }} />
          )}
          {screen === 'history' && <History />}
          {screen === 'stats' && <StatsScreen stats={stats} />}
        </div>
      </div>
    </div>
  )
}

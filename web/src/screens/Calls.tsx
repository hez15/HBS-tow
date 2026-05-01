import { useEffect, useState } from 'react'
import { nuiFetch } from '../nui'
import CallCard from '../components/CallCard'
import type { Call } from '../types'

interface Props {
  onAccepted: () => void
}

export default function Calls({ onAccepted }: Props) {
  const [calls, setCalls] = useState<Call[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    refresh()
  }, [])

  async function refresh() {
    setLoading(true)
    const data = await nuiFetch<unknown, Call[]>('getCalls')
    setCalls(data ?? [])
    setLoading(false)
  }

  async function accept(id: number) {
    const res = await nuiFetch<{ id: number }, { ok: boolean; error?: string }>('acceptCall', { id })
    if (res?.ok) onAccepted()
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Available Calls</h1>
        <button
          onClick={refresh}
          className="text-sm text-muted hover:text-white px-3 py-1.5 border border-border rounded"
        >
          Refresh
        </button>
      </div>
      {loading && <div className="text-muted">Loading...</div>}
      {!loading && calls.length === 0 && (
        <div className="text-muted">No calls available right now.</div>
      )}
      <div className="grid grid-cols-2 gap-4">
        {calls.map((c) => (
          <CallCard key={c.id} call={c} onAccept={accept} />
        ))}
      </div>
    </div>
  )
}

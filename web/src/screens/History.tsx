import { useEffect, useState } from 'react'
import { nuiFetch } from '../nui'
import type { HistoryItem } from '../types'

export default function History() {
  const [items, setItems] = useState<HistoryItem[]>([])

  useEffect(() => {
    nuiFetch<unknown, HistoryItem[]>('getHistory').then((d) => setItems(d ?? []))
  }, [])

  return (
    <div className="space-y-4">
      <h1 className="text-3xl font-bold">Recent Jobs</h1>
      {items.length === 0 && <div className="text-muted">No completed jobs yet.</div>}
      <div className="space-y-2">
        {items.map((it, i) => (
          <div
            key={i}
            className="bg-panel border border-border rounded-lg p-4 flex justify-between items-center"
          >
            <div>
              <div className="font-medium">{it.label}</div>
              <div className="text-xs text-muted">
                {new Date(it.ts * 1000).toLocaleTimeString()}
              </div>
            </div>
            <div className="text-primary font-bold">+${it.pay}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

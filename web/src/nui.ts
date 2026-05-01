import type { ActiveMission } from './types'

const RESOURCE = 'hbs-tow'

export async function nuiFetch<TIn, TOut>(name: string, data?: TIn): Promise<TOut> {
  const res = await fetch(`https://${RESOURCE}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data ?? {}),
  })
  return res.json() as Promise<TOut>
}

export type NuiInbound =
  | { action: 'open' }
  | { action: 'close' }
  | { action: 'updateActive'; payload: ActiveMission | null }

export function onNuiMessage(cb: (msg: NuiInbound) => void) {
  const handler = (e: MessageEvent) => cb(e.data as NuiInbound)
  window.addEventListener('message', handler)
  return () => window.removeEventListener('message', handler)
}

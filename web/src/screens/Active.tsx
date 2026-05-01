import { nuiFetch } from '../nui'
import type { ActiveMission } from '../types'

interface Props {
  mission: ActiveMission | null
  onAbandon: () => void
}

export default function Active({ mission, onAbandon }: Props) {
  if (!mission) {
    return (
      <div className="text-center py-20">
        <div className="text-muted">No active job.</div>
      </div>
    )
  }

  async function abandon() {
    await nuiFetch('abandon')
    onAbandon()
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Active Job</h1>
      <div className="bg-panel border border-border rounded-xl p-6">
        <div className="text-xs uppercase tracking-wider text-primary">{mission.label}</div>
        <div className="text-2xl font-semibold mt-2">{mission.district}</div>
        <div className="text-muted text-sm mt-1">Base pay: ${mission.basePay}</div>
      </div>
      <button
        onClick={abandon}
        className="w-full py-3 bg-red-900/50 hover:bg-red-900 transition rounded-xl text-white"
      >
        Abandon Job
      </button>
    </div>
  )
}

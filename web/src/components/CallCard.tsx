import type { Call } from '../types'

interface Props {
  call: Call
  onAccept: (id: number) => void
}

export default function CallCard({ call, onAccept }: Props) {
  return (
    <div
      className={`bg-panel border rounded-xl p-5 transition ${
        call.locked ? 'border-border opacity-60' : 'border-border hover:border-primary/60'
      }`}
    >
      <div className="flex justify-between items-start">
        <div>
          <div className="text-xs uppercase tracking-wider text-primary">{call.label}</div>
          <div className="text-lg font-semibold mt-1 capitalize">{call.model}</div>
          <div className="text-sm text-muted">{call.district}</div>
        </div>
        <div className="text-right">
          <div className="text-2xl font-bold">${call.basePay}</div>
          <div className="text-xs text-muted">+{call.xp} XP</div>
        </div>
      </div>
      <button
        disabled={call.locked}
        onClick={() => onAccept(call.id)}
        className="mt-4 w-full py-2 bg-primary hover:bg-primary-hover disabled:bg-border disabled:text-muted disabled:cursor-not-allowed transition rounded-lg text-white font-medium"
      >
        {call.locked ? `Requires Driving lvl ${call.minLevel}` : 'Accept'}
      </button>
    </div>
  )
}

import LevelBar from '../components/LevelBar'
import type { Stats, ActiveMission } from '../types'

interface Props {
  stats: Stats | null
  active: ActiveMission | null
  onGo: () => void
}

export default function Home({ stats, active, onGo }: Props) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Dispatch</h1>
        <p className="text-muted text-sm mt-1">Tow Truck Operator</p>
      </div>

      <div className="bg-panel rounded-xl p-6 border border-border">
        <div className="flex justify-between items-end mb-3">
          <div>
            <div className="text-muted text-xs uppercase tracking-wider">Driving Level</div>
            <div className="text-4xl font-bold mt-1">{stats?.level ?? 0}</div>
          </div>
          <div className="text-right">
            <div className="text-muted text-xs">XP</div>
            <div className="text-sm">{stats?.xpIntoLevel ?? 0} / {stats?.xpForNext ?? 0}</div>
          </div>
        </div>
        <LevelBar value={stats?.xpIntoLevel ?? 0} max={stats?.xpForNext ?? 100} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-panel rounded-xl p-5 border border-border">
          <div className="text-muted text-xs uppercase">Total Jobs</div>
          <div className="text-2xl font-bold mt-1">{stats?.jobs ?? 0}</div>
        </div>
        <div className="bg-panel rounded-xl p-5 border border-border">
          <div className="text-muted text-xs uppercase">Total Earned</div>
          <div className="text-2xl font-bold mt-1 text-primary">
            ${(stats?.earned ?? 0).toLocaleString()}
          </div>
        </div>
      </div>

      {active ? (
        <div className="bg-primary/10 border border-primary/40 rounded-xl p-5">
          <div className="text-primary text-xs uppercase tracking-wider">Active Job</div>
          <div className="text-xl font-semibold mt-1">{active.label}</div>
          <div className="text-sm text-muted">{active.district}</div>
        </div>
      ) : (
        <button
          onClick={onGo}
          className="w-full py-4 bg-primary hover:bg-primary-hover transition rounded-xl text-white font-semibold text-lg"
        >
          Find Available Calls
        </button>
      )}
    </div>
  )
}

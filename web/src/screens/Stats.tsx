import LevelBar from '../components/LevelBar'
import type { Stats } from '../types'

interface Props {
  stats: Stats | null
}

export default function StatsScreen({ stats }: Props) {
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Statistics</h1>

      <div className="bg-panel border border-border rounded-xl p-6">
        <div className="text-xs uppercase tracking-wider text-muted">Driving</div>
        <div className="flex items-end justify-between mt-2 mb-3">
          <div className="text-4xl font-bold">Level {stats?.level ?? 0}</div>
          <div className="text-sm text-muted">
            {stats?.xpIntoLevel ?? 0} / {stats?.xpForNext ?? 0} XP
          </div>
        </div>
        <LevelBar value={stats?.xpIntoLevel ?? 0} max={stats?.xpForNext ?? 100} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-panel border border-border rounded-xl p-5">
          <div className="text-muted text-xs uppercase">Jobs Completed</div>
          <div className="text-3xl font-bold mt-2">{stats?.jobs ?? 0}</div>
        </div>
        <div className="bg-panel border border-border rounded-xl p-5">
          <div className="text-muted text-xs uppercase">Total Earned</div>
          <div className="text-3xl font-bold mt-2 text-primary">
            ${(stats?.earned ?? 0).toLocaleString()}
          </div>
        </div>
      </div>
    </div>
  )
}

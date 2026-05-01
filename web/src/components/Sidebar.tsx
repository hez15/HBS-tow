const ITEMS = [
  { key: 'home', label: 'Home' },
  { key: 'calls', label: 'Calls' },
  { key: 'active', label: 'Active' },
  { key: 'history', label: 'History' },
  { key: 'stats', label: 'Stats' },
] as const

interface Props {
  current: string
  onChange: (k: string) => void
  onClose: () => void
}

export default function Sidebar({ current, onChange, onClose }: Props) {
  return (
    <div className="w-56 bg-panel border-r border-border flex flex-col">
      <div className="px-6 py-6 border-b border-border">
        <div className="text-primary font-bold text-xl tracking-wide">HBS TOW</div>
        <div className="text-muted text-xs mt-1">Dispatch</div>
      </div>
      <nav className="flex-1 py-4">
        {ITEMS.map((it) => {
          const isActive = current === it.key
          return (
            <button
              key={it.key}
              onClick={() => onChange(it.key)}
              className={`w-full text-left px-6 py-3 transition border-l-4 ${
                isActive
                  ? 'bg-primary/10 border-primary text-white'
                  : 'border-transparent text-muted hover:text-white hover:bg-white/5'
              }`}
            >
              <span className="text-sm font-medium">{it.label}</span>
            </button>
          )
        })}
      </nav>
      <button
        onClick={onClose}
        className="m-4 py-2 rounded-lg bg-border/50 hover:bg-border text-sm text-white"
      >
        Close
      </button>
    </div>
  )
}

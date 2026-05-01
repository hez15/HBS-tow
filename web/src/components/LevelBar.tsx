interface Props {
  value: number
  max: number
}

export default function LevelBar({ value, max }: Props) {
  const pct = max > 0 ? Math.min(100, (value / max) * 100) : 0
  return (
    <div className="w-full h-2 bg-border rounded-full overflow-hidden">
      <div
        className="h-full bg-primary transition-all"
        style={{ width: `${pct}%` }}
      />
    </div>
  )
}

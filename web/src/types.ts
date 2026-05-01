export interface Call {
  id: number
  variant: string
  label: string
  model: string
  coords: { x: number; y: number; z: number; w?: number }
  district: string
  basePay: number
  xp: number
  minLevel: number
  locked: boolean
}

export interface Stats {
  jobs: number
  earned: number
  level: number
  xp: number
  xpIntoLevel: number
  xpForNext: number
}

export interface ActiveMission {
  id: number
  variant: string
  label: string
  district: string
  basePay: number
}

export interface HistoryItem {
  variant: string
  label: string
  pay: number
  ts: number
}

export type Screen = 'home' | 'calls' | 'active' | 'history' | 'stats'

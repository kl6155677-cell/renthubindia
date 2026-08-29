import { Wallet, Landmark, Receipt, RefreshCcw } from 'lucide-react'
import { StatCard } from '../components/ui/StatCard'

export function FinancePage() {
  return (
    <section>
      <header className="page-header">
        <h2>Finance & Payouts (Phase 2)</h2>
      </header>
      <p className="muted">
        Initial Phase 2 scaffold. Connect this module to payment transaction endpoints when backend flows are available.
      </p>
      <div className="stats-grid section-gap">
        <StatCard label="Total transaction volume" value="0" icon={<Wallet size={20} />} color="blue" />
        <StatCard label="Platform fees collected" value="0" icon={<Landmark size={20} />} color="green" />
        <StatCard label="Pending payouts" value="0" icon={<Receipt size={20} />} color="amber" />
        <StatCard label="Refunds (30d)" value="0" icon={<RefreshCcw size={20} />} color="red" />
      </div>
      <section className="card section-gap">
        <h3>Next implementation steps</h3>
        <ul>
          <li>Integrate transaction and payout endpoints.</li>
          <li>Add payout status filters and reconciliation exports.</li>
          <li>Link dispute cases to booking and support records.</li>
        </ul>
      </section>
    </section>
  )
}

// Period filter tabs: 7d | 30d | 90d | 12m
export default function PeriodSelector({ value, onChange }) {
  const periods = [
    { value: '7d',  label: '7 days'  },
    { value: '30d', label: '30 days' },
    { value: '90d', label: '90 days' },
    { value: '12m', label: '12 months' },
  ];

  return (
    <div className="flex items-center bg-gray-100 rounded-lg p-1 gap-1">
      {periods.map(p => (
        <button
          key={p.value}
          onClick={() => onChange(p.value)}
          className={`
            px-3 py-1.5 rounded-md text-sm font-medium transition-all
            ${value === p.value
              ? 'bg-white text-[#0D6E75] shadow-sm'
              : 'text-gray-500 hover:text-gray-700'
            }
          `}
        >
          {p.label}
        </button>
      ))}
    </div>
  );
}

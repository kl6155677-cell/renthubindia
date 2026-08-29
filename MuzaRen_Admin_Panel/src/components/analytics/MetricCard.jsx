// A KPI card with value, label, growth indicator, and icon
export default function MetricCard({
  label,
  value,
  growth,     // number: +12 or -5 (percentage)
  sublabel,   // e.g. "new this month"
  icon,
  color = '#0D6E75',
  prefix = '',
  suffix = '',
}) {
  const isPositive = growth > 0;
  const isNeutral  = growth === 0 || growth === null || growth === undefined;

  return (
    <div className="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-gray-500 font-medium mb-1">{label}</p>
          <p className="text-3xl font-bold text-gray-900">
            {prefix}{typeof value === 'number'
              ? value.toLocaleString() : value}{suffix}
          </p>
          {sublabel && (
            <p className="text-xs text-gray-400 mt-1">{sublabel}</p>
          )}
        </div>
        {icon && (
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ backgroundColor: `${color}15` }}
          >
            <span style={{ color }} className="text-lg">{icon}</span>
          </div>
        )}
      </div>

      {!isNeutral && (
        <div className="mt-3 flex items-center gap-1">
          <span className={`text-sm font-semibold ${
            isPositive ? 'text-green-600' : 'text-red-500'
          }`}>
            {isPositive ? '↑' : '↓'} {Math.abs(growth)}%
          </span>
          <span className="text-xs text-gray-400">vs previous period</span>
        </div>
      )}
    </div>
  );
}

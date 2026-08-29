/**
 * Get start date based on period string.
 * period: '7d' | '30d' | '90d' | '12m' | 'all'
 */
function getStartDate(period) {
  const now = new Date();
  switch (period) {
    case '7d':  return new Date(now - 7  * 24 * 60 * 60 * 1000);
    case '30d': return new Date(now - 30 * 24 * 60 * 60 * 1000);
    case '90d': return new Date(now - 90 * 24 * 60 * 60 * 1000);
    case '12m': return new Date(now.setFullYear(now.getFullYear() - 1));
    case 'all': return new Date('2020-01-01');
    default:    return new Date(now - 30 * 24 * 60 * 60 * 1000);
  }
}

/**
 * Get previous period start date for comparison (growth %).
 * Returns the start of the period BEFORE the current one.
 */
function getPreviousPeriodStart(period) {
  const now = new Date();
  switch (period) {
    case '7d':  return new Date(now - 14 * 24 * 60 * 60 * 1000);
    case '30d': return new Date(now - 60 * 24 * 60 * 60 * 1000);
    case '90d': return new Date(now - 180 * 24 * 60 * 60 * 1000);
    case '12m': return new Date(now.setFullYear(now.getFullYear() - 2));
    default:    return new Date(now - 60 * 24 * 60 * 60 * 1000);
  }
}

/**
 * Calculate percentage change between two values.
 * Returns null if previousValue is 0 (avoid division by zero).
 */
function calculateGrowth(currentValue, previousValue) {
  if (previousValue === 0) return currentValue > 0 ? 100 : 0;
  return Math.round(((currentValue - previousValue) / previousValue) * 100);
}

/**
 * Group records by day/week/month depending on period.
 * Returns array of { date: 'YYYY-MM-DD', count: n }
 */
function groupByPeriod(records, dateField, period) {
  const groups = {};

  records.forEach(record => {
    const date = new Date(record[dateField]);
    let key;

    if (period === '7d' || period === '30d') {
      // Group by day: YYYY-MM-DD
      key = date.toISOString().split('T')[0];
    } else if (period === '90d') {
      // Group by week: YYYY-WXX
      const weekStart = new Date(date);
      weekStart.setDate(date.getDate() - date.getDay());
      key = weekStart.toISOString().split('T')[0];
    } else {
      // Group by month: YYYY-MM
      key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    }

    groups[key] = (groups[key] || 0) + 1;
  });

  // Sort by date and return as array
  return Object.entries(groups)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, count]) => ({ date, count }));
}

module.exports = { getStartDate, getPreviousPeriodStart, calculateGrowth, groupByPeriod };

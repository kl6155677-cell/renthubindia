const prisma = require('../config/db');

/**
 * Generic paginated query for any Prisma model.
 *
 * @param {string}  modelName  - Prisma model name e.g. 'user', 'listing'
 * @param {object}  where      - Prisma where clause
 * @param {object}  include    - Prisma include clause
 * @param {object}  orderBy    - Prisma orderBy clause
 * @param {number}  page       - Page number (1-based)
 * @param {number}  limit      - Records per page (max 100, default 50)
 * @param {object}  select     - Optional Prisma select clause
 * @returns {object} { data, pagination }
 */
async function paginate({
  modelName,
  where    = {},
  include  = undefined,
  select   = undefined,
  orderBy  = { createdAt: 'desc' },
  page     = 1,
  limit    = 50,
}) {
  // Sanitize inputs
  const pageNumber  = Math.max(1, parseInt(page)  || 1);
  const pageSize    = Math.min(100, Math.max(1, parseInt(limit) || 50));
  const skip        = (pageNumber - 1) * pageSize;

  // Build query args
  const queryArgs = {
    where,
    orderBy,
    take: pageSize,
    skip,
  };

  // Use either select or include (not both)
  if (select)        queryArgs.select  = select;
  else if (include)  queryArgs.include = include;

  // Run data query and count in parallel
  const [data, total] = await Promise.all([
    prisma[modelName].findMany(queryArgs),
    prisma[modelName].count({ where }),
  ]);

  const totalPages = Math.ceil(total / pageSize);

  return {
    data,
    pagination: {
      total,
      page:       pageNumber,
      limit:      pageSize,
      totalPages,
      hasNext:    pageNumber < totalPages,
      hasPrev:    pageNumber > 1,
      from:       total === 0 ? 0 : skip + 1,
      to:         Math.min(skip + pageSize, total),
    },
  };
}

/**
 * Parse page and limit from Express request query.
 * Always returns safe, sanitized values.
 */
function getPaginationParams(query) {
  return {
    page:  Math.max(1, parseInt(query.page)  || 1),
    limit: Math.min(100, Math.max(1, parseInt(query.limit) || 50)),
  };
}

module.exports = { paginate, getPaginationParams };

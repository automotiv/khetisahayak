const buildPaginationQuery = (baseQuery, { page = 1, limit = 20, maxLimit = 100 }) => {
  const sanitizedLimit = Math.min(Math.max(1, parseInt(limit) || 20), maxLimit);
  const sanitizedPage = Math.max(1, parseInt(page) || 1);
  const offset = (sanitizedPage - 1) * sanitizedLimit;

  return {
    query: `${baseQuery} LIMIT $LIMIT OFFSET $OFFSET`,
    params: { limit: sanitizedLimit, offset },
    pagination: { page: sanitizedPage, limit: sanitizedLimit, offset },
  };
};

const buildSortQuery = (allowedFields, { sortBy, sortOrder = 'DESC' }) => {
  const sanitizedOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
  
  if (!sortBy || !allowedFields.includes(sortBy)) {
    return { orderClause: '', sortBy: null, sortOrder: sanitizedOrder };
  }

  return {
    orderClause: `ORDER BY ${sortBy} ${sanitizedOrder}`,
    sortBy,
    sortOrder: sanitizedOrder,
  };
};

const buildFilterQuery = (filters, allowedFilters) => {
  const conditions = [];
  const params = [];
  let paramIndex = 1;

  for (const [field, config] of Object.entries(allowedFilters)) {
    const value = filters[field];
    if (value === undefined || value === null || value === '') continue;

    switch (config.type) {
      case 'exact':
        conditions.push(`${config.column || field} = $${paramIndex}`);
        params.push(value);
        paramIndex++;
        break;

      case 'like':
        conditions.push(`${config.column || field} ILIKE $${paramIndex}`);
        params.push(`%${value}%`);
        paramIndex++;
        break;

      case 'in':
        const values = Array.isArray(value) ? value : value.split(',');
        const placeholders = values.map((_, i) => `$${paramIndex + i}`).join(', ');
        conditions.push(`${config.column || field} IN (${placeholders})`);
        params.push(...values);
        paramIndex += values.length;
        break;

      case 'range':
        if (value.min !== undefined) {
          conditions.push(`${config.column || field} >= $${paramIndex}`);
          params.push(value.min);
          paramIndex++;
        }
        if (value.max !== undefined) {
          conditions.push(`${config.column || field} <= $${paramIndex}`);
          params.push(value.max);
          paramIndex++;
        }
        break;

      case 'boolean':
        conditions.push(`${config.column || field} = $${paramIndex}`);
        params.push(value === 'true' || value === true);
        paramIndex++;
        break;

      case 'date_range':
        if (value.from) {
          conditions.push(`${config.column || field} >= $${paramIndex}`);
          params.push(new Date(value.from));
          paramIndex++;
        }
        if (value.to) {
          conditions.push(`${config.column || field} <= $${paramIndex}`);
          params.push(new Date(value.to));
          paramIndex++;
        }
        break;
    }
  }

  return {
    whereClause: conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '',
    params,
    nextParamIndex: paramIndex,
  };
};

const buildSelectFields = (requestedFields, allowedFields, defaultFields) => {
  if (!requestedFields) {
    return defaultFields.join(', ');
  }

  const requested = requestedFields.split(',').map(f => f.trim());
  const valid = requested.filter(f => allowedFields.includes(f));

  return valid.length > 0 ? valid.join(', ') : defaultFields.join(', ');
};

const countQuery = (tableName, whereClause = '', params = []) => {
  return {
    query: `SELECT COUNT(*) as total FROM ${tableName} ${whereClause}`,
    params,
  };
};

const buildFullQuery = ({
  tableName,
  selectFields,
  joins = '',
  filters,
  allowedFilters,
  sortOptions,
  allowedSortFields,
  pagination,
}) => {
  const { whereClause, params, nextParamIndex } = buildFilterQuery(filters, allowedFilters);
  const { orderClause } = buildSortQuery(allowedSortFields, sortOptions);
  const { query: paginatedQuery, pagination: paginationInfo } = buildPaginationQuery(
    `SELECT ${selectFields} FROM ${tableName} ${joins} ${whereClause} ${orderClause}`,
    pagination
  );

  const finalQuery = paginatedQuery
    .replace('$LIMIT', `$${nextParamIndex}`)
    .replace('$OFFSET', `$${nextParamIndex + 1}`);

  return {
    query: finalQuery,
    params: [...params, paginationInfo.limit, paginationInfo.offset],
    countQuery: `SELECT COUNT(*) as total FROM ${tableName} ${joins} ${whereClause}`,
    countParams: params,
    pagination: paginationInfo,
  };
};

module.exports = {
  buildPaginationQuery,
  buildSortQuery,
  buildFilterQuery,
  buildSelectFields,
  countQuery,
  buildFullQuery,
};

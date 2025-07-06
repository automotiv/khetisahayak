const { newDb } = require('pg-mem');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');

// Simple in-memory storage for testing
const testData = {
  users: [],
  products: [],
  diagnostics: [],
  educationalContent: []
};

// Mock implementations of SQL functions
const sqlFunctions = {
  uuid_generate_v4: () => require('uuid').v4(),
  crypt: (password, salt) => `hashed_${password}`,
  gen_salt: (type) => '$2b$10$93J5aB.lmXKjdHhQ8QnQce' // bcrypt salt
};

// Helper function to parse SQL values
const parseValue = (value) => {
  if (value === 'NULL') return null;
  if (value.startsWith("'") && value.endsWith("'")) {
    return value.slice(1, -1);
  }
  return value;
};

// Helper function to execute a query against our test data
const executeQuery = (text, params = []) => {
  // Replace parameter placeholders ($1, $2, etc.) with actual values
  let processedText = text;
  if (params && params.length > 0) {
    params.forEach((param, index) => {
      const value = typeof param === 'string' ? `'${param}'` : param;
      processedText = processedText.replace(`$${index + 1}`, value);
    });
  }

  const normalizedText = processedText.trim().toUpperCase();
  
  // Handle function calls
  const functionCallMatch = normalizedText.match(/^SELECT\s+([a-z_]+)\(([^)]*)\)/i);
  if (functionCallMatch) {
    const [, funcName, argsStr] = functionCallMatch;
    const args = argsStr.split(',').map(arg => arg.trim().replace(/['"]/g, ''));
    
    if (sqlFunctions[funcName]) {
      const result = sqlFunctions[funcName](...args);
      return { rows: [{ [funcName]: result }], rowCount: 1 };
    }
  }
  
  // Handle SELECT queries
  const selectMatch = normalizedText.match(/^SELECT\s+(.*?)\s+FROM\s+(\w+)/i);
  if (selectMatch) {
    const [, columns, table] = selectMatch;
    const whereMatch = normalizedText.match(/WHERE\s+(.*?)(?:\s*$|\s+GROUP|\s+ORDER|\s+LIMIT)/i);
    
    let results = [];
    switch (table.toLowerCase()) {
      case 'users':
        results = [...testData.users];
        break;
      case 'products':
        results = [...testData.products];
        break;
      case 'diagnostics':
        results = [...testData.diagnostics];
        break;
      case 'educational_content':
        results = [...testData.educationalContent];
        break;
      default:
        console.warn(`Unknown table: ${table}`);
        return { rows: [], rowCount: 0 };
    }
    
    // Simple WHERE clause handling for testing
    if (whereMatch) {
      const whereClause = whereMatch[1];
      // Simple equality check for now
      const [field, operator, value] = whereClause.split(/\s+/);
      
      results = results.filter(row => {
        const rowValue = row[field];
        const compareValue = parseValue(value);
        
        if (operator === '=') {
          return rowValue == compareValue; // Use == for type coercion
        } else if (operator === 'LIKE') {
          const pattern = compareValue.replace(/%/g, '.*').replace(/_/g, '.');
          return new RegExp(`^${pattern}$`, 'i').test(rowValue);
        }
        return true;
      });
    }
    
    return { rows: results, rowCount: results.length };
  } 
  
  // Handle INSERT queries
  const insertMatch = normalizedText.match(/^INSERT\s+INTO\s+(\w+)\s*\(([^)]*)\)\s*VALUES\s*\(([^)]*)\)/i);
  if (insertMatch) {
    const [, table, columnsStr, valuesStr] = insertMatch;
    const columns = columnsStr.split(',').map(c => c.trim());
    const values = valuesStr.split(',').map(v => v.trim());
    
    const row = {};
    columns.forEach((col, index) => {
      row[col] = parseValue(values[index]);
    });
    
    // Generate ID if not provided
    if (!row.id) {
      row.id = sqlFunctions.uuid_generate_v4();
    }
    
    // Special handling for password hashing
    if (row.password_hash && !row.password_hash.startsWith('hashed_')) {
      row.password_hash = sqlFunctions.crypt(row.password_hash, sqlFunctions.gen_salt('bf'));
    }
    
    // Add to the appropriate table
    const targetArray = (() => {
      switch (table.toLowerCase()) {
        case 'users': return testData.users;
        case 'products': return testData.products;
        case 'diagnostics': return testData.diagnostics;
        case 'educational_content': return testData.educationalContent;
        default: throw new Error(`Unknown table: ${table}`);
      }
    })();
    
    targetArray.push(row);
    return { rowCount: 1, rows: [row] };
  }
  
  // Handle UPDATE queries
  const updateMatch = normalizedText.match(/^UPDATE\s+(\w+)\s+SET\s+(.*?)(?:\s+WHERE\s+(.*))?/i);
  if (updateMatch) {
    const [, table, setClause, whereClause] = updateMatch;
    let rows = [];
    
    // Get the target rows
    switch (table.toLowerCase()) {
      case 'users': rows = testData.users; break;
      case 'products': rows = testData.products; break;
      case 'diagnostics': rows = testData.diagnostics; break;
      case 'educational_content': rows = testData.educationalContent; break;
      default: return { rowCount: 0, rows: [] };
    }
    
    // Apply WHERE clause if present
    if (whereClause) {
      const [field, operator, value] = whereClause.split(/\s+/);
      rows = rows.filter(row => {
        const rowValue = row[field];
        const compareValue = parseValue(value);
        return operator === '=' ? rowValue == compareValue : true;
      });
    }
    
    // Apply SET clause
    const updates = setClause.split(',').map(part => {
      const [col, value] = part.split('=').map(s => s.trim());
      return { col, value: parseValue(value) };
    });
    
    let affected = 0;
    rows.forEach(row => {
      updates.forEach(({ col, value }) => {
        row[col] = value === 'DEFAULT' ? null : value;
      });
      affected++;
    });
    
    return { rowCount: affected, rows: [] };
  }
  
  // Handle DELETE queries
  const deleteMatch = normalizedText.match(/^DELETE\s+FROM\s+(\w+)(?:\s+WHERE\s+(.*))?/i);
  if (deleteMatch) {
    const [, table, whereClause] = deleteMatch;
    let rows = [];
    let targetArray;
    
    // Get the target array
    switch (table.toLowerCase()) {
      case 'users': targetArray = testData.users; break;
      case 'products': targetArray = testData.products; break;
      case 'diagnostics': targetArray = testData.diagnostics; break;
      case 'educational_content': targetArray = testData.educationalContent; break;
      default: return { rowCount: 0, rows: [] };
    }
    
    // If no WHERE clause, delete all
    if (!whereClause) {
      const count = targetArray.length;
      targetArray.length = 0;
      return { rowCount: count, rows: [] };
    }
    
    // Apply WHERE clause
    const [field, operator, value] = whereClause.split(/\s+/);
    const compareValue = parseValue(value);
    
    const remaining = [];
    let deleted = 0;
    
    for (const row of targetArray) {
      const rowValue = row[field];
      const shouldDelete = operator === '=' ? rowValue == compareValue : false;
      
      if (shouldDelete) {
        deleted++;
      } else {
        remaining.push(row);
      }
    }
    
    // Replace the array with the remaining items
    targetArray.length = 0;
    targetArray.push(...remaining);
    
    return { rowCount: deleted, rows: [] };
  }
  
  // For other queries, just return a success response
  return { rowCount: 1, rows: [] };
};

// Mock the database methods
const db = {
  // Execute a query with optional parameters
  query: async (text, params = []) => {
    try {
      // For testing, we'll handle the query directly
      return executeQuery(text, params);
    } catch (error) {
      console.error('Database query error:', { text, params, error });
      throw error;
    }
  },
  
  // Execute a query and return exactly one row, or throw if no rows
  one: async (text, params = []) => {
    const result = await executeQuery(text, params);
    if (!result.rows || result.rows.length === 0) {
      const error = new Error('No data returned from query');
      error.code = 'P0002'; // Not found error code
      throw error;
    }
    return result.rows[0];
  },
  
  // Execute a query and return one row, or null if no rows
  oneOrNone: async (text, params = []) => {
    try {
      const result = await executeQuery(text, params);
      return result.rows && result.rows.length > 0 ? result.rows[0] : null;
    } catch (error) {
      if (error.code === 'P0002') return null; // Not found
      throw error;
    }
  },
  
  // Execute a query and return multiple rows, or throw if no rows
  many: async (text, params = []) => {
    const result = await executeQuery(text, params);
    if (!result.rows || result.rows.length === 0) {
      const error = new Error('No data returned from query');
      error.code = 'P0002'; // Not found error code
      throw error;
    }
    return result.rows;
  },
  
  // Execute a query and return multiple rows, or empty array if no rows
  manyOrNone: async (text, params = []) => {
    const result = await executeQuery(text, params);
    return result.rows || [];
  },
  
  // Execute a query and return no rows
  none: async (text, params = []) => {
    const result = await executeQuery(text, params);
    return { rowCount: result.rowCount || 0, rows: [] };
  },
  
  // Transaction support (simplified for testing)
  tx: async (callback) => {
    // In test environment, just execute the callback directly
    return await callback(db);
  },
  
  // This helper will restore the database to its initial empty state before each test
  __reset: () => {
    Object.keys(testData).forEach(key => {
      testData[key] = [];
    });
  },
  
  // Helper for tests to add test data directly
  __addTestData: (table, data) => {
    if (testData[table] === undefined) {
      testData[table] = [];
    }
    
    // Ensure each item has an ID
    const preparedData = data.map(item => ({
      ...item,
      id: item.id || sqlFunctions.uuid_generate_v4()
    }));
    
    testData[table].push(...preparedData);
  },
  
  // Additional helpers for testing
  __getTestData: (table) => {
    return testData[table] ? [...testData[table]] : [];
  },
  
  __clearTestData: () => {
    Object.keys(testData).forEach(key => {
      testData[key] = [];
    });
  }
};

module.exports = db;
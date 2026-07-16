// backend/config/db.js
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'root',
  database: 'mediqr3',
  waitForConnections: true,
  connectionLimit: 10,
});

module.exports = pool;

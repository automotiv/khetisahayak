const express = require('express');
const logger = require('./utils/logger');
const swaggerUi = require('swagger-ui-express');
// const swaggerSpecs = require('./swagger');

const app = express();
const port = 5002;

// app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs));

const syncRoutes = require('./routes/sync');
app.use('/api/sync', syncRoutes);

app.get('/', (req, res) => {
  res.json({
    message: 'Kheti Sahayak Backend API',
    status: 'running'
  });
});

app.listen(port, () => {
  logger.info(`Server running on port ${port}`);
});

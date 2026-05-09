const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
const env = process.env.NODE_ENV || 'development';

app.get('/', (req, res) => {
  res.send(`<h1>Welcome to ShopFlow!</h1><p>Current Environment: <b>${env}</b></p>`);
});

app.listen(port, () => {
  console.log(`ShopFlow running on port ${port} in ${env} mode`);
});

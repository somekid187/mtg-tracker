import express from 'express';
import cors from 'cors';

const app = express();
const PORT = process.env.BACKEND_PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.status(200).json({ message: 'Welcome to the MTG Tracker!' });
});

app.listen(PORT, () => {
  console.log(`Server is running http://127.0.0.1:${PORT}`);
}).on('error', (err) => {
  console.error('Error starting server:', err);
});
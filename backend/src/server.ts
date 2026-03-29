import app from "./app";

const PORT = process.env.BACKEND_PORT || 3000;

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
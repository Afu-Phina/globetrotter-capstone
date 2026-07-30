# Use an official lightweight Python runtime as the base image
FROM python:3.12-slim

# Set a working directory inside the container
WORKDIR /app

# Copy dependency file first to leverage Docker layer caching
COPY backend/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend application source code
COPY backend/ .

# Expose the port the app runs on
EXPOSE 5000

# Run the application
CMD ["python", "run.py"]

#!/bin/bash
# Render start script for Psychology App Backend

echo "Starting Psychology App Backend..."

# Set Python path
export PYTHONPATH=$PYTHONPATH:/opt/render/project/src

# Run the application
uvicorn main:app --host 0.0.0.0 --port $PORT
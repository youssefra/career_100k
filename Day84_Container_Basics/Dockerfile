# Layer 1: Inherit a highly optimized, ultra-slim official Python runtime base image
FROM python:3.11-slim

# Layer 2: Define the internal working context path directory inside the container
WORKDIR /usr/src/app

# Layer 3: Copy our local app script file directly into the internal layer workspace
COPY app.py .

# Layer 4: Set the default execution command vector to fire when the container boots
CMD ["python", "app.py"]

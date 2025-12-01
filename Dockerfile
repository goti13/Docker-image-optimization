#############################################
# Stage 1: Builder
# This stage installs dependencies in isolation.
# The goal is to keep the final image small by
# excluding build tools and caches.
#############################################
FROM python:3.11-slim AS builder

# Set the working directory inside the container
WORKDIR /app

# Install OS packages needed to compile Python dependencies
# --no-install-recommends prevents installation of unnecessary extras
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy only the requirements file first
# This allows Docker to cache the dependency installation layer
COPY requirements.txt /app/

# Install Python dependencies into a dedicated folder
# --no-cache-dir prevents pip from storing cache files
# --target installs packages to a directory we can copy later
RUN pip install --no-cache-dir --target=/app/requirements -r requirements.txt 



#############################################
# Stage 2: Final Runtime Image
# Much smaller — contains only Python runtime +
# your application code and installed dependencies.
# Switch final image to distroless size (python:3.11-alpine)
#############################################
FROM python:3.11-alpine

# Set working directory for the runtime container
WORKDIR /app

# Copy the installed dependencies from the builder stage
# into Python's site-packages directory in the final image
COPY --from=builder /app/requirements /usr/local/lib/python3.11/site-packages/

# Copy only the actual application source code into the container
# Avoid using "COPY . /app". build-essential is installed in Stage 1, This would copy the builder layer into the final image indirectly.
COPY app.py .

# Create a non-root user for security (best practice)
RUN adduser -D appuser


# Switch to the non-root user to run the app
USER appuser

# Document that the application will listen on port 8000
EXPOSE 8000

# Command that will run when the container starts
CMD ["python3", "app.py"]

FROM envoyproxy/envoy:v1.39-latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Envoy configuration into the container
COPY envoy/envoy.yaml /etc/envoy/envoy.yaml

# Expose HTTP listener port and Admin interface port
EXPOSE 10000 9901

# Run Envoy with the custom configuration
CMD ["envoy", "-c", "/etc/envoy/envoy.yaml", "--log-level", "info"]

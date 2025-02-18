FROM apache/age

# Install Python 3 and plpython3u
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        python3 \
        postgresql-plpython3-16 \
    && rm -rf /var/lib/apt/lists/*

# The rest of the configuration remains the same
CMD ["postgres", "-c", "shared_preload_libraries=age"] 
# Use latest stable channel SDK.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and data
COPY . .

# Create data directory and set permissions
RUN mkdir -p bin/data
RUN chmod -R 755 bin/data

# Compile the server
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/
COPY --from=build /app/bin/data /app/bin/data

# Set working directory
WORKDIR /app

# Set environment variables
ENV PORT=10000
ENV DART_VM_OPTIONS="--old-gen-heap-size=512"

# Expose port
EXPOSE 10000

# Start server
CMD ["/app/bin/server"]

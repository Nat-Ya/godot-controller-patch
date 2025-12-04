# Dockerfile for building JoyCon Android Plugin
# Based on Google Cloud Artifact Registry image

FROM europe-west1-docker.pkg.dev/general-476320/android-build-images/android-build-image:latest

# Set working directory
WORKDIR /workspace

# Install additional tools if needed
# (Base image already has: Android SDK 34, Gradle 8.x, Kotlin, JDK 17)

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV GRADLE_USER_HOME=/workspace/.gradle

# Copy gradle wrapper if present
COPY android/gradle ./android/gradle
COPY android/gradlew ./android/gradlew

# Make gradlew executable
RUN chmod +x ./android/gradlew

# Pre-download Gradle dependencies (optional, speeds up subsequent builds)
COPY android/build.gradle.kts ./android/
COPY android/settings.gradle.kts ./android/
RUN cd android && gradle dependencies || true

# Default command
CMD ["bash"]

# ------------------------------------------------------------------------------
# Build Stage
# ------------------------------------------------------------------------------
FROM adoptopenjdk/openjdk8-openj9:alpine-slim AS build
# Minecraft Version
ENV MCVERSION=1.16.1
# Build stage workdir
WORKDIR /tmp/papermc
# Download Paperclip
ADD https://papermc.io/api/v1/paper/${MCVERSION}/latest/download /tmp/papermc/paperclip.jar
# Run Paperclip to generate patched minecraft server jar
RUN /opt/java/openjdk/bin/java -jar /tmp/papermc/paperclip.jar --version
# ------------------------------------------------------------------------------
# Runtime Stage
# ------------------------------------------------------------------------------
FROM adoptopenjdk/openjdk8-openj9:alpine-slim AS runtime
LABEL maintainer="chawyehsu@hotmail.com"
# Runtime Memory Size
ENV MEMORYSIZE=1G
# Pre-defined Java Flags
# https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft
ENV JAVAFLAGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true"
# Obtain patched minecraft server jar from build stage
COPY --from=build /tmp/papermc/cache/patched*.jar /opt/papermc/paperspigot.jar
# Runtime stage workdir
WORKDIR /data
# Volumes for the persistence data (Plugins, Worlds, Logs, Configs...)
VOLUME "/data"
# Expose minecraft port
EXPOSE 25565/tcp
# Entrypoint
ENTRYPOINT /opt/java/openjdk/bin/java -jar -Xms${MEMORYSIZE} -Xmx${MEMORYSIZE} ${JAVAFLAGS} /opt/papermc/paperspigot.jar --nojline nogui

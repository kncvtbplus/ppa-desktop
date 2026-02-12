FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /workspace

# Copy the full Maven project (path contains spaces, so use JSON form)
COPY ["PPA sourcecode/project/PPA/", "/workspace/PPA/"]

# Build an executable Spring Boot jar
WORKDIR /workspace/PPA
RUN mvn -DskipTests package


FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy the Spring Boot jar (pom.xml sets <finalName>application</finalName>)
COPY --from=build /workspace/PPA/target/application.jar /app/application.jar

# Default JVM and application environment (can be overridden via docker-compose)
ENV JAVA_OPTS="-Xms512m -Xmx2g" \
    RDS_HOSTNAME="postgres" \
    RDS_PORT="5432" \
    RDS_USERNAME="ppa" \
    RDS_PASSWORD="Automation" \
    RSERVE_HOST="rserve" \
    RSERVE_PORT="6311" \
    S3_BUCKET="local-ppa-bucket" \
    AWS_REGION="us-east-1" \
    AWS_DEFAULT_REGION="us-east-1"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.io.tmpdir=/tmp -jar /app/application.jar"]


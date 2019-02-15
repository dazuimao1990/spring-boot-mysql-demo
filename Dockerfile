FROM frolvlad/alpine-java:jdk8-full AS builder
  2 #FROM openjdk:8-jdk
  3
  4 ARG MAVEN_VERSION=3.6.0
  5 ARG USER_HOME_DIR="/root"
  6 ARG SHA=fae9c12b570c3ba18116a4e26ea524b29f7279c17cbaadc3326ca72927368924d9131d11b9e851b8dc9162228b6fdea955446be41207a5cfc61283dd8a561d2f
  7 ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries
  8
  9 RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
 10   && apk add --no-cache curl bash  \
 11   && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
 12   && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
 13   && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
 14   && rm -f /tmp/apache-maven.tar.gz \
 15   && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
 16
 17 ENV MAVEN_HOME /usr/share/maven
 18 ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
 19
 20 COPY mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
 21 RUN  sed -i '/<mirrors>/a\ <mirror>\n<id>goodrain-repo</id>\n<name>goodrain repo</name>\n<url>http://maven.goodrain.me</url>\n<mirrorOf>central</mirrorOf>\n</mirror>' ${MAVEN    _HOME}/conf/settings.xml
 22 COPY settings-docker.xml /usr/share/maven/ref/
 23
 24 #ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]
 25 #CMD ["mvn"]
 26 RUN mkdir /app
 27
 28 COPY . /app/
 29
 30 WORKDIR /app
 31
 32 RUN mvn -B -DskipTests=true clean install
 33
 34 FROM frolvlad/alpine-java:jre8-full
 35
 36 RUN mkdir /app && \
 37     cd /app
 38
 39 COPY --from=builder /app/target /app/target
 40
 41 EXPOSE 5000
 42
 43 ENTRYPOINT ["java -Dserver.port=$PORT $JAVA_OPTS -jar target/*.jar"]

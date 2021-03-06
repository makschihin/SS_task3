FROM openjdk:latest
RUN mkdir /opt/tests/
WORKDIR /opt/tests/
COPY spring-petclinic-2.5.0-SNAPSHOT.jar .
ENTRYPOINT ["java", "-Dspring.profiles.active=mysql","-jar", "spring-petclinic-2.5.0-SNAPSHOT.jar"]
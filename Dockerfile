FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server
EXPOSE 8080
CMD ["./bin/server"]
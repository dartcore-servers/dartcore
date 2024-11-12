FROM dart:stable
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
EXPOSE 8080
CMD ["dart", "run", "bin/main.dart"]
// ignore_for_file: non_constant_identifier_names

import 'package:dartcore/custom_types.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:postgres/postgres.dart';

/// Database class, for MySQL
class Database {
  /// Host (e.g. 127.0.0.1)
  final String host;

  /// Port for the host, e.g. 3600
  final int port;

  /// Username for the database
  final String user;

  /// Password for the database
  final String password;

  /// Database name
  final String database;

  /// Database Type
  final DatabaseType type;

  /// Constructor

  Database({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    required this.type,
  });

  /// MySQLConnection

  MySQLConnection? conn;

  /// PostgreSQLConnection
  Connection? conn2;

  /// Inits the database
  Future<void> init() async {
    if (type.asString == "mysql") {
      conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: user,
        password: password,
        databaseName: database,
      );
    } else {
      conn2 = await Connection.open(Endpoint(
        host: host,
        port: port,
        username: user,
        password: password,
        database: database,
      ));
    }
  }

  /// Connect to the database (MySQL ONLY)
  Future<void> connect() async {
    await conn!.connect();
  }

  /// Executes a query
  /// Returns an IResultSet in case of MySQL
  /// and Returns Result in case of PostgreSQL
  /// [iterable] is only usable for MySQL
  Future<dynamic> exec(
    String query, [
    Map<String, dynamic>? args,
    bool? iterable = false,
  ]) async {
    if (type.asString == "mysql") {
      return await conn!.execute('SELECT * FROM users', args, iterable!);
    } else if (type.asString == "postgres") {
      return await conn2!.execute(query, parameters: args);
    }
  }

  /// Closes the connection
  Future<void> close() async {
    await conn!.close();
  }
}

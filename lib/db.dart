import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

@DataClassName('Factory')
class Factories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
}

class Workers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get factoryId => integer()();
}

@UseMoor(tables: [Factories, Workers])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> populate() {
    return transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
      final f1id = await into(factories).insert(
        FactoriesCompanion.insert(name: 'Avtovaz'),
      );
      final f2id = await into(factories).insert(
        FactoriesCompanion.insert(name: 'BMW'),
      );
      await into(workers).insert(
        WorkersCompanion.insert(name: 'Ivan', factoryId: f1id),
      );
      await into(workers).insert(
        WorkersCompanion.insert(name: 'Petr', factoryId: f1id),
      );
      await into(workers).insert(
        WorkersCompanion.insert(name: 'John', factoryId: f2id),
      );
      await into(workers).insert(
        WorkersCompanion.insert(name: 'David', factoryId: f2id),
      );
      await into(workers).insert(
        WorkersCompanion.insert(name: 'Richard', factoryId: f2id),
      );
    });
  }

  Future<List<FactoryWithWorkers>> query() async {
    final query = select(factories).join([
      leftOuterJoin(workers, workers.factoryId.equalsExp(factories.id)),
    ]);
    final rows = await query.get();
    // print(rows.map((e) => e.rawData.data));
    final groupedRows = rows.groupBy((row) => row.read(factories.id));
    final groupedFactories = groupedRows.entries.map((entry) {
      final factoryId = entry.key;
      final rows = entry.value;
      final workersList = rows.map((row) => row.readTable(workers)).toList();
      final factoriesList =
          rows.map((row) => row.readTable(factories)).toList();
      final String factoryName = factoriesList.first.name;
      assert(factoriesList.every(
        (factory) => factory.id == factoryId && factory.name == factoryName,
      ));
      return FactoryWithWorkers(
        factoryName,
        workersList.map((worker) => worker.name).toList(),
      );
    }).toList();
    return groupedFactories;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

class FactoryWithWorkers {
  final String factoryName;
  final List<String> workerNames;

  FactoryWithWorkers(this.factoryName, this.workerNames);

  @override
  String toString() {
    return '$factoryName [${workerNames.join(', ')}]';
  }
}

extension IterableX<T> on Iterable<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) key) {
    final map = <K, List<T>>{};
    for (final element in this) {
      (map[key(element)] ??= []).add(element);
    }
    return map;
  }
}

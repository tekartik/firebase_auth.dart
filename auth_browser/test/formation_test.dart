import 'package:dev_test/test.dart';
import 'package:meta/meta.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/model/model.dart';

class FormationDefRow {
  int weight;
  List<int> places;

  FormationDefRow({@required this.places, int weight}) : weight = weight ?? 1 {
    assert(weight > 0);
    assert(places != null);
  }

  // list is either [1,2,3] or [[1,2,3]] or [[1,2,3], 2] last member being the weight
  FormationDefRow.fromList(List list) {
    if (list?.isNotEmpty ?? false) {
      if (list.first is int) {
        list = [list];
      }

      places = (list.first as List)?.cast<int>();
      if (list.length > 1) {
        weight = list[1] as int;
      }
    }
    weight ??= 1;
  }
}

class Formation {
  List<FormationDefRow> rows;
  final String id;
  final String name;

  Formation({this.id, this.name, this.rows, List def}) {
    if (rows == null) {
      if (def?.isNotEmpty ?? false) {
        var first = def.first;

        // Handle simple definition
        if (first is int) {
          def = [def];
        }
        /*else if (first is List) {
          if (first.isNotEmpty) {
            var listFirst = first.first;
            if (listFirst is int) {
              def = [def];
            }
          }
        }

         */
      }
      rows = def
          .map((rowDef) => FormationDefRow.fromList(rowDef as List))
          ?.toList(growable: false);
    }
  }

  Model toMap() {
    var map = Model();
    map.setValue('id', id);
    map.setValue('name', name);
    if (rows?.isNotEmpty ?? false) {
      var places = [];
      double totalYWeight = 0;
      rows.forEach((row) {
        totalYWeight += row.weight.toDouble();
      });

      double currentYWeight = 0;
      rows.forEach((row) {
        var y = (currentYWeight + (row.weight / 2)) / totalYWeight;
        currentYWeight += row.weight;
        // devPrint('y $y');

        var totalXWeight = row.places.length;
        int currentXWeight = 0;
        row.places.forEach((place) {
          var x = (currentXWeight + .5) / totalXWeight;
          currentXWeight++;
          // devPrint('x $x');
          if (place != null) {
            places.add({'id': place.toString(), 'x': x, 'y': y});
          }
        });
      });
      map['places'] = places;
    }
    return map;
  }
}

void main() {
  group('formation', () {
    test('defRow', () {
      var row = FormationDefRow.fromList([1, 2, 3]);
      expect(row.places, [1, 2, 3]);
      expect(row.weight, 1);

      row = FormationDefRow.fromList([
        [1, 2, 3],
        2
      ]);
      expect(row.places, [1, 2, 3]);
      expect(row.weight, 2);
    });
    test('simplest', () {
      var formation = Formation(def: [1]);
      expect(formation.toMap(), {
        'places': [
          {'place': '1', 'x': 0.5, 'y': 0.5}
        ]
      });
    });
    test('basic_x', () {
      var formation = Formation(def: [1, 2]);
      expect(formation.toMap(), {
        'places': [
          {'id': '1', 'x': 0.25, 'y': 0.5},
          {'id': '2', 'x': 0.75, 'y': 0.5}
        ]
      });
    });
    test('basic_y', () {
      var formation = Formation(def: [
        [
          [1],
          2
        ]
      ]);
      expect(formation.toMap(), {
        'places': [
          {'id': '1', 'x': 0.5, 'y': 0.5}
        ]
      });
      formation = Formation(def: [
        [1],
        [2]
      ]);
      expect(formation.toMap(), {
        'places': [
          {'id': '1', 'x': 0.5, 'y': 0.25},
          {'id': '2', 'x': 0.5, 'y': 0.75}
        ]
      });
    });
    test('442', () {
      var def442 = [
        [1],
        [2, 5, 6, 3],
        [7, 4, 8, 11],
        [10, 9]
      ];
      var formation = Formation(def: def442, id: '442', name: '4-4-2');
      expect(formation.toMap(), {
        'id': '442',
        'name': '4-4-2',
        'places': [
          {'id': '1', 'x': 0.5, 'y': 0.125},
          {'id': '2', 'x': 0.125, 'y': 0.375},
          {'id': '5', 'x': 0.375, 'y': 0.375},
          {'id': '6', 'x': 0.625, 'y': 0.375},
          {'id': '3', 'x': 0.875, 'y': 0.375},
          {'id': '7', 'x': 0.125, 'y': 0.625},
          {'id': '4', 'x': 0.375, 'y': 0.625},
          {'id': '8', 'x': 0.625, 'y': 0.625},
          {'id': '11', 'x': 0.875, 'y': 0.625},
          {'id': '10', 'x': 0.25, 'y': 0.875},
          {'id': '9', 'x': 0.75, 'y': 0.875}
        ]
      });
    });
    test('more', () {
      var formation = Formation(def: [
        [1],
        [
          [2, 3],
          3
        ]
      ]);
      expect(formation.toMap(), {
        'places': [
          {'place': '1', 'x': 0.5, 'y': 0.5}
        ]
      });
    });
  });
}

import 'dart:async';
import 'package:conduit/conduit.dart';

class Intersect<T extends ManagedObject> {
  Intersect._(this.removed, this.added, this.updated);

  factory Intersect.from(Iterable<T> current, Iterable<T> source) {
    Iterable<T> removed;
    Iterable<T> added;
    Iterable<T> updated;

    if (current.isNotEmpty && source.isEmpty) {
      removed = [];
      added = current;
      updated = [];
    } else if (current.isEmpty && source.isNotEmpty) {
      removed = source;
      added = [];
      updated = [];
    } else if (current.isEmpty && source.isEmpty) {
      removed = [];
      added = [];
      updated = [];
    } else {
      final cSet = current.toSet();
      final sSet = source.toSet();
      updated = cSet.intersection(sSet);
      added = cSet.difference(sSet);
      removed = sSet.difference(cSet);
    }
    return Intersect._(removed, added, updated);
  }

  final Iterable<T> removed;
  final Iterable<T> added;
  final Iterable<T> updated;

  Future<void> updateDb(ManagedContext context, dynamic field(T x),
      {FutureOr<bool> onAdd(Query<T> x)?,
      FutureOr<void> onAfterAdd(T inserted, T x)?,
      FutureOr<bool> onUpdate(Query<T> x)?,
      FutureOr<void> onAfterUpdate(T? updated, T x)?}) async {
    await remove(context, field);
    await add(context, onAdd: onAdd, onAfterAdd: onAfterAdd);
    await update(context, field,
        onUpdate: onUpdate, onAfterUpdate: onAfterUpdate);
  }

  Future<void> remove(ManagedContext context, dynamic field(T x)) async {
    if (removed.isNotEmpty) {
      final rq = Query<T>(context)..where(field).oneOf(removed.map(field));
      await rq.delete();
    }
  }

  Future<void> add(ManagedContext context,
      {FutureOr<bool> onAdd(Query<T> x)?,
      FutureOr<void> onAfterAdd(T inserted, T x)?}) async {
    if (added.isNotEmpty) {
      for (var a in added) {
        T? inserted;
        final query = Query<T>(context)..values = a;
        if (onAdd != null) {
          if (await onAdd(query)) {
            inserted = await query.insert();
          }
        } else {
          inserted = await query.insert();
        }
        if (onAfterAdd != null && inserted != null) {
          await onAfterAdd(inserted, a);
        }
      }
    }
  }

  Future<void> update(ManagedContext context, dynamic field(T x),
      {FutureOr<bool> onUpdate(Query<T> x)?,
      FutureOr<void> onAfterUpdate(T? updated, T x)?}) async {
    if (updated.isNotEmpty) {
      for (var u in updated) {
        T? updated;
        final query = Query<T>(context)
          ..values = u
          ..where(field).equalTo(field(u));
        if (onUpdate != null) {
          if (await onUpdate(query)) {
            updated = await query.updateOne();
          }
        } else {
          updated = await query.updateOne();
        }
        if (onAfterUpdate != null) {
          await onAfterUpdate(updated, u);
        }
      }
    }
  }
}

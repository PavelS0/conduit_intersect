import 'dart:async';
import 'package:aqueduct/aqueduct.dart';

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

  Future<void> updateDb(ManagedContext context, dynamic field(T x), {FutureOr<bool> onAdd(T x), FutureOr<void> onAfterAdd(T inserted, T x), FutureOr<bool> onUpdate(T x), FutureOr<void> onAfterUpdate(T updated, T x)}) async {
   await remove(context, field);
   await add(context, onAdd: onAdd, onAfterAdd: onAfterAdd);
   await update(context, field, onUpdate: onUpdate, onAfterUpdate: onAfterUpdate);
  }

  Future<void> remove(ManagedContext context, dynamic field(T x))  async {
     if (removed.isNotEmpty) {
      final rq = Query<T>(context)
        ..where(field)
        .oneOf(removed.map(field));
      await rq.delete();
    }
  }

  Future<void> add(ManagedContext context, {FutureOr<bool> onAdd(T x), FutureOr<void> onAfterAdd(T inserted, T x)})  async {
    
    if (added.isNotEmpty) {
      for (var a in added) {
        T inserted;
        if (onAdd != null) {
          if (await onAdd(a)) {
            inserted = await context.insertObject(a);
          }
        } else {
          inserted = await context.insertObject(a);
        }
        if (onAfterAdd != null) {
          onAfterAdd(inserted, a);
        }
      }
    }
  }
  
  Future<T> _upd(ManagedContext context, T u, dynamic field(T x)) async {
     final uq = Query<T>(context)
      ..values = u
      ..where(field).equalTo(field(u));
    return await uq.updateOne();
  }
  
  Future<void> update(ManagedContext context, dynamic field(T x), {FutureOr<bool> onUpdate(T x), FutureOr<void> onAfterUpdate(T updated, T x)})  async {
    if (updated.isNotEmpty) {
      for (var u in updated) {
        T updated;
        if (onUpdate != null) {
          if(await onUpdate(u)) {
            updated = await _upd(context, u, field);
          }
        } else {
          updated = await _upd(context, u, field);
        }
        if (onAfterUpdate != null) {
          onAfterUpdate(updated, u);
        }
      }
    }
  }
}
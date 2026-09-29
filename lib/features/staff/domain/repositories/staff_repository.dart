import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';

/// Le fichier du personnel tel que la tablette le connaît — lecture 100 %
/// locale.
abstract class StaffRepository {
  Future<Either<Failure, StaffFileSnapshot>> loadFile();
}

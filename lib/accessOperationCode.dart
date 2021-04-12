enum AccessOperationCode {
  read,
  write,
  lock,
  kill,
  block_write,
  block_erase,
  recommission,
  block_permalock,
  nxp_set_eas,
  nxp_read_protect,
  nxp_reset_read_protect,
  nxp_change_config,
  impinj_qt_read,
  impinj_qt_write,
  none,
}

AccessOperationCode accessOperationCodeFromOrdial(int ordinal) => AccessOperationCode.values.firstWhere((element) => element.ordinal == ordinal, orElse: () => AccessOperationCode.none);

extension AccessOperationCodeExtensions on AccessOperationCode {
  int get ordinal {
    switch (this) {
      case AccessOperationCode.read: return 0;
      case AccessOperationCode.write: return 1;
      case AccessOperationCode.lock: return 2;
      case AccessOperationCode.kill: return 3;
      case AccessOperationCode.block_write: return 4;
      case AccessOperationCode.block_erase: return 5;
      case AccessOperationCode.recommission: return 6;
      case AccessOperationCode.block_permalock: return 7;
      case AccessOperationCode.nxp_set_eas: return 8;
      case AccessOperationCode.nxp_read_protect: return 9;
      case AccessOperationCode.nxp_reset_read_protect: return 10;
      case AccessOperationCode.nxp_change_config: return 22;
      case AccessOperationCode.impinj_qt_read: return 21;
      case AccessOperationCode.impinj_qt_write: return 20;
      case AccessOperationCode.none: return 0xFF;
      default:
        throw Exception("Unsupported AccessOperationCode");
    }
  }
}
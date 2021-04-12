enum MemoryBank {
  epc,
  tid,
  user,
  resv,
  none,
  access,
  kill,
  all,
}

MemoryBank memoryBankFromKey(int key) => MemoryBank.values.firstWhere((element) => element.key == key, orElse: () => MemoryBank.all);

extension MemoryBankExtensions on MemoryBank {
  int get key {
    switch (this) {
      case MemoryBank.epc: return 0x01;
      case MemoryBank.tid: return 0x02;
      case MemoryBank.user: return 0x04;
      case MemoryBank.resv: return 0x08;
      case MemoryBank.none: return 0x10;
      case MemoryBank.access: return 0x20;
      case MemoryBank.kill: return 0x40;
      case MemoryBank.all: return 0x67;
      default:
        throw Exception("Unsupported MemoryBank");
    }
  }
}
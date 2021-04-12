class ReportConfig {
  final bool includeFirstSeenTime;
  final bool includePhase;
  final bool includePC;
  final bool includeRSSI;
  final bool includeChannelIndex;
  final bool includeLastSeenTime;
  final bool includeTagSeenCount;

  ReportConfig({
    this.includeFirstSeenTime = false, 
    this.includePhase = false, 
    this.includePC = false, 
    this.includeRSSI = false, 
    this.includeChannelIndex = false, 
    this.includeLastSeenTime = false, 
    this.includeTagSeenCount = false
  });
}
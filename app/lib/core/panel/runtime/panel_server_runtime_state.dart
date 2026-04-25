import 'panel_live_overview_data.dart';

enum PanelServerRuntimeStatus {
  idle,
  loading,
  connected,
  failed,
}

class PanelServerRuntimeState {
  const PanelServerRuntimeState({
    required this.status,
    this.overview,
    this.message,
    this.syncedAt,
  });

  final PanelServerRuntimeStatus status;
  final PanelLiveOverviewData? overview;
  final String? message;
  final DateTime? syncedAt;

  bool get isLoading => status == PanelServerRuntimeStatus.loading;
  bool get hasLiveData => overview != null;
  bool get hasError =>
      status == PanelServerRuntimeStatus.failed && message != null;

  factory PanelServerRuntimeState.idle() {
    return const PanelServerRuntimeState(status: PanelServerRuntimeStatus.idle);
  }

  factory PanelServerRuntimeState.loading({
    PanelLiveOverviewData? previousOverview,
    DateTime? previousSyncedAt,
  }) {
    return PanelServerRuntimeState(
      status: PanelServerRuntimeStatus.loading,
      overview: previousOverview,
      syncedAt: previousSyncedAt,
    );
  }

  factory PanelServerRuntimeState.connected(PanelLiveOverviewData overview) {
    return PanelServerRuntimeState(
      status: PanelServerRuntimeStatus.connected,
      overview: overview,
      syncedAt: overview.shotTime ?? DateTime.now(),
    );
  }

  factory PanelServerRuntimeState.failed(
    String message, {
    PanelLiveOverviewData? previousOverview,
    DateTime? previousSyncedAt,
  }) {
    return PanelServerRuntimeState(
      status: PanelServerRuntimeStatus.failed,
      overview: previousOverview,
      message: message,
      syncedAt: previousSyncedAt,
    );
  }
}

enum EteeloSelectPanelMode { popover, sheet }

class EteeloSelectItem<T> {
  final T value;
  final String label;
  final bool enabled;

  const EteeloSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });
}

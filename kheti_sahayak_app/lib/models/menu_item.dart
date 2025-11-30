class MenuItem {
  final int id;
  final String label;
  final String iconName;
  final String routeId;
  final int displayOrder;

  MenuItem({
    required this.id,
    required this.label,
    required this.iconName,
    required this.routeId,
    required this.displayOrder,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      label: json['label'],
      iconName: json['icon_name'],
      routeId: json['route_id'],
      displayOrder: json['display_order'],
    );
  }
}

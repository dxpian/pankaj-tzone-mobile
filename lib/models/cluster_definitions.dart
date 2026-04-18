
class ClusterDefinition {
  final String name;
  final List<String> loggers;

  ClusterDefinition({required this.name, required this.loggers});
}

/// ---- HARD-CODED CLUSTERS ----
/// Add all clusters your boss listed.
final List<ClusterDefinition> clusters = [
  ClusterDefinition(
    name: "Saitama Logistic Center",
    loggers: ["190123000001", "190123000002", "190123000003"],
  ),
  ClusterDefinition(
    name: "Suginami Branch",
    loggers: ["190123000010", "190123000011"],
  ),
  ClusterDefinition(
    name: "Itabashi-Kita B",
    loggers: ["190123000020"],
  ),
  ClusterDefinition(
    name: "Setagaya B",
    loggers: ["190123000030", "190123000031"],
  ),
  ClusterDefinition(
    name: "Fuchu B",
    loggers: ["190123000040"],
  ),
  ClusterDefinition(
    name: "Ome B",
    loggers: ["190123000050"],
  ),
  ClusterDefinition(
    name: "Niza B",
    loggers: ["190123000060"],
  ),
  ClusterDefinition(
    name: "Tokorozawa B",
    loggers: ["190123000070", "190123000071"],
  ),
  ClusterDefinition(
    name: "Urawa B",
    loggers: ["190123000080"],
  ),
  ClusterDefinition(
    name: "Omiya B",
    loggers: ["190123000090"],
  ),
  ClusterDefinition(
    name: "Kawagoe B",
    loggers: ["190123000100"],
  ),
  ClusterDefinition(
    name: "Machida B",
    loggers: ["190123000110"],
  ),
  ClusterDefinition(
    name: "Kumagaya B",
    loggers: ["190123000120"],
  ),
  ClusterDefinition(
    name: "Sapporo B",
    loggers: ["190123000130"],
  ),
  ClusterDefinition(
    name: "Shin Sapporo B",
    loggers: ["190123000140"],
  ),
  ClusterDefinition(
    name: "Bunkyo Pharmaceutical Center",
    loggers: ["190123000150", "190123000151", "190123000152"],
  ),
];
